import { spawnSync } from "node:child_process";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { stripVTControlCharacters } from "node:util";
import {
  getSelectListTheme,
  type ExtensionAPI,
  type ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import {
  SelectList,
  truncateToWidth,
  type TuiMouseEvent,
} from "@earendil-works/pi-tui";
import { Type } from "typebox";
import {
  BackgroundJobStore,
  isActiveJob,
  isFailedJob,
  type BackgroundJob,
  type JobState,
} from "./job-store.ts";

const STATUS_KEY = "background-jobs";
const DEFAULT_LOG_LIMIT_MB = 5;

const Parameters = Type.Object({
  action: Type.Union([
    Type.Literal("start"),
    Type.Literal("list"),
    Type.Literal("tail"),
    Type.Literal("cancel"),
  ]),
  command: Type.Optional(Type.String({ description: "Foreground command to start" })),
  label: Type.Optional(Type.String({ description: "Short label for a new job" })),
  cwd: Type.Optional(Type.String({ description: "Working directory for a new job" })),
  jobId: Type.Optional(Type.String({ description: "Job ID or unique prefix" })),
});

const icons: Record<JobState, string> = {
  starting: "●",
  running: "●",
  "cancel-requested": "◐",
  succeeded: "✓",
  failed: "!",
  cancelled: "×",
  unknown: "!",
};

function logLimit(): number {
  const configured = Number(process.env.PI_BACKGROUND_JOBS_LOG_LIMIT_MB);
  const megabytes = Number.isFinite(configured) && configured > 0
    ? Math.min(100, Math.max(1, configured))
    : DEFAULT_LOG_LIMIT_MB;
  return Math.round(megabytes * 1024 * 1024);
}

function elapsed(job: BackgroundJob): string {
  const start = Date.parse(job.startedAt ?? job.createdAt);
  const end = job.finishedAt ? Date.parse(job.finishedAt) : Date.now();
  const seconds = Math.max(0, Math.round((end - start) / 1000));
  if (seconds >= 3600) return `${Math.floor(seconds / 3600)}h${Math.floor((seconds % 3600) / 60)}m`;
  if (seconds >= 60) return `${Math.floor(seconds / 60)}m${seconds % 60}s`;
  return `${seconds}s`;
}

function plain(text: string): string {
  return stripVTControlCharacters(text)
    .replace(/\r/gu, "")
    .replace(/[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f]/gu, "");
}

function summary(job: BackgroundJob): string {
  const result = job.exitCode !== undefined
    ? ` exit ${job.exitCode}`
    : job.signal
    ? ` ${job.signal}`
    : "";
  return `${icons[job.state]} ${job.id} ${job.state}${result} ${elapsed(job)} — ${plain(job.label)}`;
}

function cleanTail(output: string): string {
  return plain(output)
    .split("\n")
    .slice(-20)
    .join("\n")
    .trim();
}

function details(job: BackgroundJob, output: string): string {
  return [
    summary(job),
    `cwd: ${plain(job.cwd)}`,
    `command: ${plain(job.command)}`,
    `log: ${plain(job.logPath)}${job.outputLimited ? " (older output removed)" : ""}`,
    ...(job.error ? [`note: ${plain(job.error)}`] : []),
    "",
    cleanTail(output) || "(no output yet)",
  ].join("\n");
}

function lastLogLine(store: BackgroundJobStore, job: BackgroundJob): string {
  const lines = cleanTail(store.tail(job.id, 1024)).split("\n").filter(Boolean);
  return lines.at(-1) ?? "(no output yet)";
}

type InspectorAction =
  | { type: "open"; jobId: string }
  | { type: "cancel"; jobId: string };

export default function backgroundJobsExtension(pi: ExtensionAPI): void {
  let store: BackgroundJobStore | undefined;
  let sessionId: string | undefined;
  let context: ExtensionContext | undefined;
  let shuttingDown = false;

  function updateStatus(): void {
    if (!context) return;
    const jobs = store?.list() ?? [];
    const running = jobs.filter(isActiveJob).length;
    const failed = jobs.filter(isFailedJob).length;
    if (!running && !failed) {
      context.ui.setStatus(STATUS_KEY, undefined);
      return;
    }
    const text = [
      running ? `${running} running` : "",
      failed ? `${failed} failed` : "",
    ].filter(Boolean).join(" · ");
    context.ui.setStatus(
      STATUS_KEY,
      context.ui.theme.fg(failed ? "error" : "accent", `jobs ${text}`),
    );
  }

  function completed(job: BackgroundJob): void {
    if (shuttingDown) return;
    const mode = process.env.PI_BACKGROUND_JOBS_COMPLETION?.toLowerCase() ?? "notify";
    if (mode === "silent") return;
    const message = `Background job ${summary(job)}`;
    if (mode === "wake") {
      pi.sendMessage(
        {
          customType: "background-job-complete",
          content: `${message}. Inspect it with background_job action=tail if relevant.`,
          display: false,
          details: { job },
        },
        { triggerTurn: true, deliverAs: "followUp" },
      );
    } else {
      context?.ui.notify(message, isFailedJob(job) ? "error" : "info");
    }
  }

  async function getStore(ctx: ExtensionContext): Promise<BackgroundJobStore> {
    const id = ctx.sessionManager.getSessionId();
    if (store && id === sessionId) return store;
    if (store) await store.shutdown();

    // In-memory sessions (--no-session) report an empty session directory.
    const sessionDir = ctx.sessionManager.getSessionDir();
    const directory = sessionDir
      ? join(sessionDir, "background-jobs", id)
      : join(tmpdir(), "pi-background-jobs", id);
    const next = new BackgroundJobStore(
      directory,
      {
        logLimitBytes: logLimit(),
        onChange: updateStatus,
        onTerminal: completed,
        onError: (error) => context?.ui.notify(
          `Background job monitor error: ${error.message}`,
          "error",
        ),
      },
    );
    next.init();
    store = next;
    sessionId = id;
    updateStatus();
    return next;
  }

  async function inspectJobs(
    ctx: ExtensionContext,
    jobStore: BackgroundJobStore,
  ): Promise<InspectorAction | undefined> {
    const jobs = jobStore.list();
    if (!jobs.length) {
      ctx.ui.notify("No managed background jobs in this session.", "info");
      return undefined;
    }

    return ctx.ui.custom<InspectorAction | undefined>((tui, theme, _keys, done) => {
      const listOffset = 2;
      const items = jobs.map((job) => ({
        value: job.id,
        label: summary(job),
        description: lastLogLine(jobStore, job),
      }));
      const list = new SelectList(
        items,
        Math.min(10, jobs.length),
        getSelectListTheme(),
      );
      list.onSelect = (item) => done({ type: "open", jobId: item.value });
      list.onCancel = () => done(undefined);

      const refresh = setInterval(() => {
        for (const item of items) {
          const job = jobStore.get(item.value);
          if (!job) continue;
          item.label = summary(job);
          item.description = lastLogLine(jobStore, job);
        }
        tui.requestRender();
      }, 500);
      return {
        render(width: number): string[] {
          const clickHint = tui.mode === "fullscreen" ? "/click" : "";
          const lines = [
            theme.fg("accent", theme.bold("Background jobs")),
            theme.fg(
              "dim",
              `j/k: move · l/Enter${clickHint}: open · c: cancel · h/Esc: close`,
            ),
            ...list.render(width),
          ];
          const selected = list.getSelectedItem();
          if (!selected) return lines.map((line) => truncateToWidth(line, width));

          const job = jobStore.get(selected.value);
          if (!job) return lines.map((line) => truncateToWidth(line, width));
          const output = cleanTail(jobStore.tail(job.id, 4096));
          const command = plain(job.command).replace(/\s+/gu, " ").trim();
          lines.push(
            "",
            theme.fg("borderMuted", "─".repeat(Math.max(1, width))),
            `${theme.fg("accent", "$ ")}${theme.fg("text", command)}`,
            theme.fg("muted", summary(job)),
            theme.fg("dim", `log: ${plain(job.logPath)}`),
            "",
          );
          const outputLines = output
            ? output.split("\n").slice(-8)
            : [theme.fg("dim", "(no output yet)")];
          const preview = [
            ...Array<string>(8 - outputLines.length).fill(""),
            ...outputLines,
          ];
          for (const line of preview) lines.push(`  ${theme.fg("text", line)}`);
          return lines.map((line) => truncateToWidth(line, width, theme.fg("dim", "…")));
        },
        handleInput(data: string): void {
          const selected = list.getSelectedItem();
          const index = selected
            ? items.findIndex((item) => item.value === selected.value)
            : 0;
          if (data === "j" || data === "k") {
            const direction = data === "j" ? 1 : -1;
            list.setSelectedIndex((index + direction + items.length) % items.length);
            tui.requestRender();
            return;
          }
          if (data === "l" && selected) {
            done({ type: "open", jobId: selected.value });
            return;
          }
          if (data === "h") {
            done(undefined);
            return;
          }
          if (data === "c") {
            const job = selected && jobStore.get(selected.value);
            if (job && isActiveJob(job)) done({ type: "cancel", jobId: job.id });
            return;
          }
          list.handleInput(data);
          tui.requestRender();
        },
        handleMouse(event: TuiMouseEvent) {
          const listHeight = list.render(event.width).length;
          if (event.y < listOffset || event.y >= listOffset + listHeight) return undefined;
          const result = list.handleMouse({
            ...event,
            y: event.y - listOffset,
            height: listHeight,
          });
          if (result?.handled) tui.requestRender();
          return result;
        },
        invalidate(): void {
          list.invalidate();
        },
        dispose(): void {
          clearInterval(refresh);
        },
      };
    });
  }

  async function openFullLog(ctx: ExtensionContext, job: BackgroundJob): Promise<void> {
    const ownerPane = process.env.TMUX_PANE;
    if (process.env.TMUX && ownerPane) {
      const split = spawnSync(
        "tmux",
        [
          "split-window", "-v", "-p", "35", "-c", job.cwd, "-t", ownerPane,
          "-P", "-F", "#{pane_id}",
          "tail", "-n", "+1", "-F", "--", job.logPath,
        ],
        { cwd: job.cwd, encoding: "utf8", env: process.env },
      );
      const pane = split.stdout.trim();
      if (split.status === 0 && pane) {
        spawnSync("tmux", ["select-pane", "-t", pane, "-T", `Job ${job.id}: ${job.label}`], {
          stdio: "ignore",
          env: process.env,
        });
        ctx.ui.notify(`Live log opened in tmux pane ${pane}.`, "info");
        return;
      }
    }

    const error = await ctx.ui.custom<string | undefined>((tui, _theme, _keys, done) => {
      // Pi has no SIGINT listener outside Ctrl+Z suspend; Ctrl+C in less would otherwise kill Pi.
      const ignoreSigint = (): void => {};
      process.on("SIGINT", ignoreSigint);
      let result: ReturnType<typeof spawnSync>;
      try {
        tui.stop();
        result = spawnSync("less", ["+F", "--", job.logPath], {
          cwd: job.cwd,
          stdio: "inherit",
          env: process.env,
        });
      } finally {
        process.removeListener("SIGINT", ignoreSigint);
        tui.start();
        tui.requestRender(true);
      }
      done(result.error?.message);
      return { render: () => [], invalidate() {} };
    });
    if (error) ctx.ui.notify(`Could not open log viewer: ${error}`, "error");
  }

  async function showJobs(ctx: ExtensionContext): Promise<void> {
    if (ctx.mode !== "tui") return;
    const jobStore = await getStore(ctx);
    while (true) {
      const action = await inspectJobs(ctx, jobStore);
      if (!action) return;
      const job = jobStore.get(action.jobId);
      if (!job) continue;
      if (action.type === "open") {
        await openFullLog(ctx, job);
        return;
      }
      if (
        await ctx.ui.confirm(`Cancel job ${job.id}?`, job.label)
      ) {
        await jobStore.cancel(job.id);
      }
    }
  }

  pi.registerTool({
    name: "background_job",
    label: "Background job",
    description:
      "Manage session-owned background shell jobs. Actions: start (command, optional label/cwd), list, tail (jobId), cancel (jobId). Pass a foreground command; do not append '&' or use nohup.",
    promptSnippet: "Start, inspect, and cancel managed background shell jobs.",
    promptGuidelines: [
      "Use background_job instead of shell '&' or nohup for work that should continue in the background.",
      "Inspect relevant or failed jobs with action=tail, and cancel jobs when no longer needed.",
    ],
    parameters: Parameters,
    annotations: {
      readOnlyHint: false,
      destructiveHint: true,
      idempotentHint: false,
      openWorldHint: true,
    },
    async execute(_id, params, _signal, _update, ctx) {
      const jobStore = await getStore(ctx);
      if (params.action === "start") {
        if (!params.command?.trim()) throw new Error("command is required for action=start");
        const cwd = params.cwd ? resolve(ctx.cwd, params.cwd) : ctx.cwd;
        const job = jobStore.start(params.command, cwd, params.label);
        return {
          content: [{ type: "text", text: `Started ${summary(job)}\nLog: ${job.logPath}` }],
          details: { action: "start", job },
        };
      }
      if (params.action === "list") {
        const jobs = jobStore.list();
        return {
          content: [{
            type: "text",
            text: jobs.length ? jobs.map(summary).join("\n") : "No managed background jobs.",
          }],
          details: { action: "list", jobs },
        };
      }
      if (!params.jobId?.trim()) throw new Error(`jobId is required for action=${params.action}`);
      const job = jobStore.get(params.jobId);
      if (!job) throw new Error(`Unknown or ambiguous job ID: ${params.jobId}`);
      if (params.action === "tail") {
        return {
          content: [{ type: "text", text: details(job, jobStore.tail(job.id, 12 * 1024)) }],
          details: { action: "tail", job },
        };
      }
      const cancelled = await jobStore.cancel(job.id);
      return {
        content: [{ type: "text", text: summary(cancelled) }],
        details: { action: "cancel", job: cancelled },
      };
    },
  });

  pi.registerCommand("bg", {
    description: "Start a managed background shell job",
    handler: async (args, ctx) => {
      if (!args.trim()) return ctx.ui.notify("Usage: /bg <command>", "warning");
      try {
        const jobStore = await getStore(ctx);
        const job = jobStore.start(args, ctx.cwd);
        ctx.ui.notify(`Started ${summary(job)}`, "info");
      } catch (error) {
        ctx.ui.notify(`Could not start job: ${(error as Error).message}`, "error");
      }
    },
  });

  pi.registerCommand("jobs", {
    description: "Inspect and cancel managed background shell jobs",
    handler: async (_args, ctx) => {
      try {
        await showJobs(ctx);
      } catch (error) {
        ctx.ui.notify(`Could not inspect jobs: ${(error as Error).message}`, "error");
      }
    },
  });

  pi.on("session_start", async (_event, ctx) => {
    shuttingDown = false;
    context = ctx;
    await getStore(ctx);
  });

  pi.on("session_shutdown", async (_event, ctx) => {
    shuttingDown = true;
    try {
      await store?.shutdown();
    } finally {
      ctx.ui.setStatus(STATUS_KEY, undefined);
      context = undefined;
      store = undefined;
      sessionId = undefined;
    }
  });
}
