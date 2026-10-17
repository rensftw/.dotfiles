import { randomBytes } from "node:crypto";
import { spawn, spawnSync, type ChildProcess } from "node:child_process";
import {
  chmodSync,
  closeSync,
  mkdirSync,
  openSync,
  readFileSync,
  readSync,
  renameSync,
  statSync,
  truncateSync,
  unlinkSync,
  writeFileSync,
} from "node:fs";
import { join, resolve } from "node:path";

export type JobState =
  | "starting"
  | "running"
  | "cancel-requested"
  | "succeeded"
  | "failed"
  | "cancelled"
  | "unknown";

export interface BackgroundJob {
  id: string;
  label: string;
  command: string;
  cwd: string;
  state: JobState;
  createdAt: string;
  startedAt?: string;
  finishedAt?: string;
  pid?: number;
  processIdentity?: string;
  exitCode?: number;
  signal?: string;
  error?: string;
  logPath: string;
  outputLimited: boolean;
}

export interface JobStoreOptions {
  logLimitBytes: number;
  pollIntervalMs?: number;
  onChange?: () => void;
  onTerminal?: (job: BackgroundJob) => void;
  onError?: (error: Error) => void;
}

interface ExitOutcome {
  code: number | null;
  signal: NodeJS.Signals | null;
  error?: string;
}

const ACTIVE = new Set<JobState>(["starting", "running", "cancel-requested"]);
const TERMINAL = new Set<JobState>(["succeeded", "failed", "cancelled", "unknown"]);
const STATES = new Set<JobState>([...ACTIVE, ...TERMINAL]);
const LOG_TAIL_BYTES = 256 * 1024;
const CANCEL_GRACE_MS = 1500;

const now = (): string => new Date().toISOString();
const sleep = (ms: number): Promise<void> => new Promise((resolveSleep) => setTimeout(resolveSleep, ms));

export const isActiveJob = (job: BackgroundJob): boolean => ACTIVE.has(job.state);
export const isFailedJob = (job: BackgroundJob): boolean => job.state === "failed" || job.state === "unknown";

function parseStoredJob(value: unknown, directory: string): BackgroundJob | undefined {
  if (!value || typeof value !== "object") return undefined;
  const stored = value as Partial<BackgroundJob>;
  if (
    typeof stored.id !== "string" ||
    !/^[a-f0-9]{8}$/u.test(stored.id) ||
    typeof stored.label !== "string" ||
    typeof stored.command !== "string" ||
    typeof stored.cwd !== "string" ||
    typeof stored.createdAt !== "string" ||
    typeof stored.state !== "string" ||
    !STATES.has(stored.state as JobState)
  ) return undefined;

  const job: BackgroundJob = {
    id: stored.id,
    label: stored.label,
    command: stored.command,
    cwd: stored.cwd,
    state: stored.state as JobState,
    createdAt: stored.createdAt,
    logPath: join(directory, `${stored.id}.log`),
    outputLimited: stored.outputLimited === true,
  };
  if (typeof stored.startedAt === "string") job.startedAt = stored.startedAt;
  if (typeof stored.finishedAt === "string") job.finishedAt = stored.finishedAt;
  if (typeof stored.pid === "number") job.pid = stored.pid;
  if (typeof stored.processIdentity === "string") job.processIdentity = stored.processIdentity;
  if (typeof stored.exitCode === "number") job.exitCode = stored.exitCode;
  if (typeof stored.signal === "string") job.signal = stored.signal;
  if (typeof stored.error === "string") job.error = stored.error;
  return job;
}

function identity(pid: number): string | undefined {
  if (process.platform === "win32") return undefined;
  const result = spawnSync("ps", ["-o", "lstart=", "-p", String(pid)], {
    encoding: "utf8",
    timeout: 1000,
  });
  return result.status === 0 ? result.stdout.trim() || undefined : undefined;
}

function groupAlive(pid: number): boolean {
  try {
    process.kill(process.platform === "win32" ? pid : -pid, 0);
    return true;
  } catch (error) {
    return (error as NodeJS.ErrnoException).code === "EPERM";
  }
}

function signalGroup(pid: number, signal: NodeJS.Signals): void {
  process.kill(process.platform === "win32" ? pid : -pid, signal);
}

function labelFor(command: string): string {
  const compact = command.replace(/\s+/gu, " ").trim();
  return compact.length > 60 ? `${compact.slice(0, 59)}…` : compact;
}

export class BackgroundJobStore {
  private readonly registryPath: string;
  private readonly jobs = new Map<string, BackgroundJob>();
  private readonly owned = new Set<string>();
  private readonly outcomes = new Map<string, ExitOutcome>();
  private timer?: NodeJS.Timeout;
  private stopping = false;

  constructor(
    private readonly directory: string,
    private readonly options: JobStoreOptions,
  ) {
    this.registryPath = join(directory, "jobs.json");
  }

  init(): void {
    mkdirSync(this.directory, { recursive: true, mode: 0o700 });
    chmodSync(this.directory, 0o700);

    let contents: string | undefined;
    try {
      contents = readFileSync(this.registryPath, "utf8");
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error;
    }
    if (contents !== undefined) {
      let stored: { version?: number; jobs?: unknown[] } | undefined;
      try {
        const parsed: unknown = JSON.parse(contents);
        if (parsed && typeof parsed === "object") stored = parsed as typeof stored;
      } catch {
        stored = undefined;
      }
      if (!stored) {
        const aside = `${this.registryPath}.corrupt-${Date.now()}`;
        renameSync(this.registryPath, aside);
        this.report(new Error(`Ignored unreadable job registry; moved it to ${aside}.`));
      } else if (stored.version === 1 && Array.isArray(stored.jobs)) {
        for (const value of stored.jobs) {
          const job = parseStoredJob(value, this.directory);
          if (job) this.jobs.set(job.id, job);
        }
      }
    }

    let changed = false;
    for (const job of this.jobs.values()) {
      if (!isActiveJob(job)) continue;
      if (this.matches(job)) {
        job.state = "running";
      } else {
        job.state = "unknown";
        job.finishedAt = now();
        job.error = "Could not confirm the process after restoring the session.";
      }
      changed = true;
    }
    if (changed) this.persist();

    this.timer = setInterval(() => {
      try {
        this.poll();
      } catch (error) {
        this.report(error);
      }
    }, this.options.pollIntervalMs ?? 2000);
    this.timer.unref();
    this.options.onChange?.();
  }

  list(): BackgroundJob[] {
    return [...this.jobs.values()]
      .map((job) => ({ ...job }))
      .sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  }

  get(idOrPrefix: string): BackgroundJob | undefined {
    const job = this.resolve(idOrPrefix);
    return job ? { ...job } : undefined;
  }

  start(command: string, cwd: string, label?: string): BackgroundJob {
    const trimmed = command.trim();
    if (!trimmed) throw new Error("A command is required.");

    const absoluteCwd = resolve(cwd);
    if (!statSync(absoluteCwd).isDirectory()) throw new Error(`Not a directory: ${absoluteCwd}`);

    let id: string;
    do id = randomBytes(4).toString("hex");
    while (this.jobs.has(id));

    const job: BackgroundJob = {
      id,
      label: label?.trim() ? labelFor(label) : labelFor(trimmed),
      command: trimmed,
      cwd: absoluteCwd,
      state: "starting",
      createdAt: now(),
      logPath: join(this.directory, `${id}.log`),
      outputLimited: false,
    };
    this.jobs.set(id, job);
    this.persist();
    this.options.onChange?.();

    let descriptor: number | undefined;
    let child: ChildProcess;
    try {
      descriptor = openSync(job.logPath, "a", 0o600);
      chmodSync(job.logPath, 0o600);
      child = spawn(process.env.SHELL || "/bin/sh", ["-lc", trimmed], {
        cwd: absoluteCwd,
        detached: process.platform !== "win32",
        env: process.env,
        stdio: ["ignore", descriptor, descriptor],
      });
    } catch (error) {
      if (descriptor !== undefined) closeSync(descriptor);
      return this.finish(id, "failed", { error: (error as Error).message });
    }
    closeSync(descriptor);

    child.once("error", (error) => {
      const state = this.jobs.get(id)?.state;
      if (state && TERMINAL.has(state)) return;
      this.outcomes.set(id, { code: null, signal: null, error: error.message });
      this.queueReconcile(id);
    });
    child.once("exit", (code, signal) => {
      const state = this.jobs.get(id)?.state;
      if (state && TERMINAL.has(state)) return;
      this.outcomes.set(id, { code, signal });
      this.queueReconcile(id);
    });
    child.unref();

    if (!child.pid) return this.finish(id, "failed", { error: "The shell returned no process ID." });
    this.owned.add(id);
    job.pid = child.pid;
    job.processIdentity = identity(child.pid);
    job.startedAt = now();
    job.state = "running";
    this.persist();
    this.options.onChange?.();
    return { ...job };
  }

  tail(idOrPrefix: string, maxBytes = 8192): string {
    const job = this.resolve(idOrPrefix);
    if (!job) throw new Error(`Unknown or ambiguous job ID: ${idOrPrefix}`);
    try {
      const size = statSync(job.logPath).size;
      const length = Math.min(Math.max(1, maxBytes), size);
      if (!length) return "";
      const buffer = Buffer.alloc(length);
      const fd = openSync(job.logPath, "r");
      try {
        readSync(fd, buffer, 0, length, size - length);
      } finally {
        closeSync(fd);
      }
      return buffer.toString("utf8");
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code === "ENOENT") return "";
      throw error;
    }
  }

  async cancel(idOrPrefix: string, reason = "Cancelled by user"): Promise<BackgroundJob> {
    const job = this.resolve(idOrPrefix);
    if (!job) throw new Error(`Unknown or ambiguous job ID: ${idOrPrefix}`);
    if (!isActiveJob(job)) return { ...job };

    job.state = "cancel-requested";
    job.error = reason;
    this.persist();
    this.options.onChange?.();

    if (!job.pid || (!this.owned.has(job.id) && !this.matches(job))) {
      return this.finish(job.id, "unknown", {
        error: "Refused to signal a process whose identity could not be confirmed.",
      });
    }

    try {
      signalGroup(job.pid, "SIGTERM");
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code !== "ESRCH") {
        return this.finish(job.id, "unknown", { error: (error as Error).message });
      }
    }

    for (let elapsed = 0; elapsed < CANCEL_GRACE_MS; elapsed += 100) {
      if (!groupAlive(job.pid)) return this.finish(job.id, "cancelled", { error: reason });
      await sleep(100);
    }

    try {
      signalGroup(job.pid, "SIGKILL");
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code !== "ESRCH") {
        return this.finish(job.id, "unknown", { error: (error as Error).message });
      }
    }
    await sleep(100);
    return groupAlive(job.pid)
      ? this.finish(job.id, "unknown", { error: "Could not confirm exit after SIGKILL." })
      : this.finish(job.id, "cancelled", { error: reason });
  }

  async shutdown(): Promise<void> {
    if (this.stopping) return;
    this.stopping = true;
    if (this.timer) clearInterval(this.timer);
    const ids = this.list().filter(isActiveJob).map((job) => job.id);
    await Promise.all(ids.map((id) => this.cancel(id, "Pi session shutdown")));
  }

  private resolve(idOrPrefix: string): BackgroundJob | undefined {
    const exact = this.jobs.get(idOrPrefix);
    if (exact) return exact;
    const matches = [...this.jobs.values()].filter((job) => job.id.startsWith(idOrPrefix));
    return matches.length === 1 ? matches[0] : undefined;
  }

  private matches(job: BackgroundJob): boolean {
    return Boolean(
      job.pid &&
      job.processIdentity &&
      groupAlive(job.pid) &&
      identity(job.pid) === job.processIdentity,
    );
  }

  private queueReconcile(id: string): void {
    const timer = setTimeout(() => {
      try {
        this.reconcile(id);
      } catch (error) {
        this.report(error);
      }
    }, 50);
    timer.unref();
  }

  private reconcile(id: string): void {
    const job = this.jobs.get(id);
    if (!job?.pid || !isActiveJob(job) || groupAlive(job.pid)) return;
    const outcome = this.outcomes.get(id);
    if (job.state === "cancel-requested") {
      this.finish(id, "cancelled", { signal: outcome?.signal ?? undefined, error: job.error });
    } else if (outcome?.error) {
      this.finish(id, "failed", { error: outcome.error });
    } else if (outcome?.code === 0) {
      this.finish(id, "succeeded", { exitCode: 0 });
    } else if (outcome) {
      this.finish(id, "failed", {
        exitCode: outcome.code ?? undefined,
        signal: outcome.signal ?? undefined,
      });
    }
  }

  private poll(): void {
    if (this.stopping) return;
    let changed = false;
    for (const job of this.jobs.values()) {
      changed = this.refreshLog(job) || changed;
      if (!isActiveJob(job) || !job.pid) continue;
      if (this.owned.has(job.id)) {
        if (!groupAlive(job.pid)) this.reconcile(job.id);
      } else if (job.state !== "cancel-requested" && !this.matches(job)) {
        this.finish(job.id, "unknown", {
          error: "The restored process ended; its exit status is unavailable.",
        });
      }
    }
    if (changed) this.persist();
  }

  private refreshLog(job: BackgroundJob): boolean {
    try {
      const file = statSync(job.logPath);
      if (file.size <= this.options.logLimitBytes) return false;

      const length = Math.min(
        LOG_TAIL_BYTES,
        Math.max(1, Math.floor(this.options.logLimitBytes / 2)),
        file.size,
      );
      const tail = Buffer.alloc(length);
      const fd = openSync(job.logPath, "r");
      try {
        readSync(fd, tail, 0, length, file.size - length);
      } finally {
        closeSync(fd);
      }
      const marker = Buffer.from(
        `[Earlier output removed after exceeding ${this.options.logLimitBytes} bytes.]\n`,
      );
      truncateSync(job.logPath, 0);
      writeFileSync(job.logPath, Buffer.concat([marker, tail]), { flag: "a", mode: 0o600 });
      job.outputLimited = true;
      return true;
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code === "ENOENT") return false;
      throw error;
    }
  }

  private finish(
    id: string,
    state: Extract<JobState, "succeeded" | "failed" | "cancelled" | "unknown">,
    outcome: Pick<BackgroundJob, "exitCode" | "signal" | "error">,
  ): BackgroundJob {
    const job = this.jobs.get(id);
    if (!job) throw new Error(`Unknown job ID: ${id}`);
    if (TERMINAL.has(job.state)) return { ...job };

    job.state = state;
    job.finishedAt = now();
    job.exitCode = outcome.exitCode;
    job.signal = outcome.signal;
    job.error = outcome.error;
    this.owned.delete(id);
    this.outcomes.delete(id);
    this.refreshLog(job);
    this.persist();
    const snapshot = { ...job };
    this.options.onChange?.();
    this.options.onTerminal?.(snapshot);
    return snapshot;
  }

  private persist(): void {
    const temp = `${this.registryPath}.${process.pid}.${randomBytes(3).toString("hex")}.tmp`;
    try {
      writeFileSync(temp, `${JSON.stringify({ version: 1, jobs: this.list() }, null, 2)}\n`, {
        mode: 0o600,
      });
      chmodSync(temp, 0o600);
      renameSync(temp, this.registryPath);
    } finally {
      try {
        unlinkSync(temp);
      } catch (error) {
        if ((error as NodeJS.ErrnoException).code !== "ENOENT") throw error;
      }
    }
  }

  private report(error: unknown): void {
    this.options.onError?.(error instanceof Error ? error : new Error(String(error)));
  }
}
