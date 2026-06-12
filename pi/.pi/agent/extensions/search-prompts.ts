/**
 * Search Prompts Extension
 *
 * Ctrl+R (or /search-prompts) opens fzf over previous user prompts and
 * restores the selected prompt into the current pi input editor.
 *
 * Optional scope: PI_SEARCH_PROMPTS_SCOPE=current|project|all (default: all).
 */

import type {
  ExtensionAPI,
  ExtensionContext,
  SessionEntry,
  SessionMessageEntry,
} from "@earendil-works/pi-coding-agent";
import { SessionManager } from "@earendil-works/pi-coding-agent";
import { spawnSync } from "node:child_process";
import { existsSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { homedir, tmpdir } from "node:os";
import { join, resolve, sep } from "node:path";

interface PromptRecord {
  text: string;
  timestamp: number;
  cwd: string;
  sessionFile?: string;
  entryId?: string;
}

interface FzfResult {
  prompt?: string;
  error?: string;
}

const PREVIEW_SCRIPT = String.raw`#!/usr/bin/env node
const { readFileSync } = require("node:fs");

const [query = "", file] = process.argv.slice(2);
if (!file) process.exit(0);

let text = "";
try {
  text = readFileSync(file, "utf8");
} catch (error) {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
}

function sanitizeForTerminal(value) {
  return value
    // OSC hyperlinks/title changes and other string controls can corrupt fzf's preview pane.
    .replace(/\x1B\][\s\S]*?(?:\x07|\x1B\\)/g, "")
    .replace(/\x9D[\s\S]*?(?:\x07|\x9C)/g, "")
    // DCS/PM/APC string controls.
    .replace(/\x1B[P^_][\s\S]*?\x1B\\/g, "")
    .replace(/[\x90\x98\x9E\x9F][\s\S]*?\x9C/g, "")
    // CSI/SGR/cursor movement and single-character ESC sequences.
    .replace(/\x1B\[[0-?]*[ -/]*[@-~]/g, "")
    .replace(/\x9B[0-?]*[ -/]*[@-~]/g, "")
    .replace(/\x1B[@-Z\\-_]/g, "")
    .replace(/\r\n?/g, "\n")
    // Drop remaining terminal control bytes, but keep tab and newline.
    .replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F]/g, "");
}

function escapeRegExp(value) {
  return value.replace(/[.*+?^\${}()|[\]\\]/g, "\\$&");
}

function queryTerms(value) {
  const terms = [];
  const parts = value.match(/"[^"]+"|'[^']+'|\S+/g) || [];

  for (const raw of parts) {
    let term = raw.trim();
    if (!term || term === "|") continue;

    // Ignore fzf negation terms. They are filters, not positive highlights.
    if (term.startsWith("!")) continue;

    term = term.replace(/^\|+/, "").replace(/\|+$/, "");
    term = term.replace(/^\^/, "").replace(/\$$/, "");

    // fzf's leading single quote means exact-match; shell/user quotes are also common.
    term = term.replace(/^['"]/, "").replace(/['"]$/, "");
    term = term.trim();

    if (term) terms.push(term);
  }

  return [...new Set(terms)].sort((a, b) => b.length - a.length);
}

text = sanitizeForTerminal(text);

const terms = queryTerms(query);
if (terms.length === 0) {
  process.stdout.write(text);
  process.exit(0);
}

const pattern = new RegExp("(" + terms.map(escapeRegExp).join("|") + ")", "giu");
process.stdout.write(text.replace(pattern, "\x1b[30;43m$1\x1b[0m"));
`;

function isMessageEntry(entry: SessionEntry): entry is SessionMessageEntry {
  return entry.type === "message";
}

function userMessageText(content: unknown): string {
  if (typeof content === "string") return content;
  if (!Array.isArray(content)) return "";

  return content
    .map((part) => {
      if (!part || typeof part !== "object") return "";
      const block = part as { type?: unknown; text?: unknown };
      if (block.type === "text" && typeof block.text === "string") return block.text;
      if (block.type === "image") return "[image]";
      return "";
    })
    .filter(Boolean)
    .join("\n");
}

function collectFromEntries(
  entries: SessionEntry[],
  cwd: string,
  sessionFile: string | undefined,
  records: PromptRecord[],
): void {
  for (const entry of entries) {
    if (!isMessageEntry(entry) || entry.message.role !== "user") continue;

    const text = userMessageText(entry.message.content);
    if (!text.trim()) continue;

    const timestamp =
      typeof entry.message.timestamp === "number"
        ? entry.message.timestamp
        : Number.isFinite(Date.parse(entry.timestamp))
          ? Date.parse(entry.timestamp)
          : 0;

    records.push({
      text,
      timestamp,
      cwd,
      sessionFile,
      entryId: entry.id,
    });
  }
}

async function collectPromptHistory(ctx: ExtensionContext): Promise<PromptRecord[]> {
  const records: PromptRecord[] = [];
  const currentFile = ctx.sessionManager.getSessionFile();
  const currentFileResolved = currentFile ? resolve(currentFile) : undefined;
  const currentHeader = ctx.sessionManager.getHeader();

  collectFromEntries(
    ctx.sessionManager.getEntries() as SessionEntry[],
    currentHeader?.cwd || ctx.cwd,
    currentFile,
    records,
  );

  const scope = (process.env.PI_SEARCH_PROMPTS_SCOPE ?? "all").toLowerCase();
  if (scope === "current") return newestFirst(records);

  const sessions = scope === "project"
    ? await SessionManager.list(ctx.cwd)
    : await SessionManager.listAll();

  for (const session of sessions) {
    if (currentFileResolved && resolve(session.path) === currentFileResolved) continue;

    try {
      const manager = SessionManager.open(session.path);
      collectFromEntries(
        manager.getEntries(),
        manager.getHeader()?.cwd || session.cwd || ctx.cwd,
        session.path,
        records,
      );
    } catch {
      // Skip malformed or concurrently modified session files.
    }
  }

  return newestFirst(dedupeByOccurrence(records));
}

function newestFirst(records: PromptRecord[]): PromptRecord[] {
  return [...records].sort((a, b) => b.timestamp - a.timestamp);
}

function dedupeByOccurrence(records: PromptRecord[]): PromptRecord[] {
  const seen = new Set<string>();
  const unique: PromptRecord[] = [];

  for (const record of records) {
    const key = `${record.sessionFile ?? "<memory>"}\0${record.entryId ?? ""}\0${record.text}`;
    if (seen.has(key)) continue;
    seen.add(key);
    unique.push(record);
  }

  return unique;
}

function formatTimestamp(timestamp: number): string {
  if (!timestamp) return "unknown";

  const date = new Date(timestamp);
  if (Number.isNaN(date.getTime())) return "unknown";

  const pad = (value: number) => String(value).padStart(2, "0");
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())} ${pad(date.getHours())}:${pad(date.getMinutes())}`;
}

function projectLabel(cwd: string): string {
  if (!cwd) return "unknown";

  const home = homedir();
  const shortened = cwd === home ? "~" : cwd.startsWith(`${home}${sep}`) ? `~${cwd.slice(home.length)}` : cwd;
  const parts = shortened.split(/[\\/]+/).filter(Boolean);

  if (shortened === "/" || shortened === "~") return shortened;
  if (parts.length <= 2) return shortened;
  return `…/${parts.slice(-2).join("/")}`;
}

function sanitizeForTerminal(text: string): string {
  return text
    // OSC hyperlinks/title changes and other string controls can corrupt fzf's preview pane.
    .replace(/\x1B\][\s\S]*?(?:\x07|\x1B\\)/g, "")
    .replace(/\x9D[\s\S]*?(?:\x07|\x9C)/g, "")
    // DCS/PM/APC string controls.
    .replace(/\x1B[P^_][\s\S]*?\x1B\\/g, "")
    .replace(/[\x90\x98\x9E\x9F][\s\S]*?\x9C/g, "")
    // CSI/SGR/cursor movement and single-character ESC sequences.
    .replace(/\x1B\[[0-?]*[ -/]*[@-~]/g, "")
    .replace(/\x9B[0-?]*[ -/]*[@-~]/g, "")
    .replace(/\x1B[@-Z\\-_]/g, "")
    .replace(/\r\n?/g, "\n")
    // Drop remaining terminal control bytes, but keep tab and newline.
    .replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F]/g, "");
}

function oneLine(text: string): string {
  return text.replace(/\s+/g, " ").trim();
}

function truncate(text: string, maxChars: number): string {
  const chars = Array.from(text);
  if (chars.length <= maxChars) return text;
  return `${chars.slice(0, Math.max(0, maxChars - 1)).join("")}…`;
}

function shellQuote(value: string): string {
  return `'${value.replace(/'/g, `'\\''`)}'`;
}

function writeFzfFiles(records: PromptRecord[]): { dir: string; input: string; previewScript: string } {
  const dir = mkdtempSync(join(tmpdir(), "pi-search-prompts-"));
  const previewScript = join(dir, "preview.cjs");
  writeFileSync(previewScript, PREVIEW_SCRIPT, { mode: 0o700 });

  const input = records
    .map((record, index) => {
      const promptPath = join(dir, `${String(index).padStart(6, "0")}.txt`);
      writeFileSync(promptPath, record.text, "utf8");

      const columns = [
        promptPath,
        formatTimestamp(record.timestamp),
        projectLabel(record.cwd),
        truncate(oneLine(sanitizeForTerminal(record.text)), 300),
      ];

      return columns.join("\t");
    })
    .join("\n");

  return { dir, input: `${input}\n`, previewScript };
}

function fzfAvailable(): boolean {
  const result = spawnSync("fzf", ["--version"], { stdio: "ignore" });
  return !result.error && result.status === 0;
}

function runFzf(records: PromptRecord[], ctx: ExtensionContext, initialQuery = ""): Promise<FzfResult> {
  return ctx.ui.custom<FzfResult>((tui, _theme, _keybindings, done) => {
    const { dir, input, previewScript } = writeFzfFiles(records);
    const previewCommand = `${shellQuote(process.execPath)} ${shellQuote(previewScript)} {q} {1}`;

    const args = [
      "--ansi",
      "--delimiter=\t",
      "--with-nth=2,3,4..",
      // fzf applies --nth to the transformed display line when --with-nth is used.
      // Displayed fields are: 1=timestamp, 2=project, 3=prompt preview.
      "--nth=3..",
      "--layout=reverse",
      "--height=90%",
      "--border=rounded",
      "--cycle",
      "--prompt=prompt history> ",
      "--header=Type to search • Enter populates the pi input • Esc cancels",
      "--preview-window=right:60%:wrap:border-left",
      "--preview",
      previewCommand,
    ];

    if (initialQuery.trim()) {
      args.push("--query", initialQuery.trim());
    }

    let result: FzfResult = {};

    try {
      tui.stop();
      process.stdout.write("\x1b[2J\x1b[H");

      const fzf = spawnSync("fzf", args, {
        input,
        encoding: "utf8",
        env: process.env,
        stdio: ["pipe", "pipe", "inherit"],
        maxBuffer: 1024 * 1024,
      });

      if (fzf.error) {
        result = { error: fzf.error.message };
      } else if (fzf.status === 0) {
        const selectedLine = (fzf.stdout ?? "").split(/\r?\n/, 1)[0] ?? "";
        const promptPath = selectedLine.split("\t", 1)[0];

        if (promptPath && existsSync(promptPath)) {
          result = { prompt: readFileSync(promptPath, "utf8") };
        } else {
          result = { error: "fzf did not return a prompt selection." };
        }
      } else if (fzf.status !== 130 && fzf.status !== 1) {
        result = { error: `fzf exited with status ${fzf.status ?? "unknown"}.` };
      }
    } catch (error) {
      result = { error: error instanceof Error ? error.message : String(error) };
    } finally {
      try {
        rmSync(dir, { recursive: true, force: true });
      } catch {}

      tui.start();
      tui.requestRender(true);
      done(result);
    }

    return { render: () => [], invalidate: () => {} };
  });
}

async function openPromptSearch(ctx: ExtensionContext, initialQuery = ""): Promise<void> {
  if (!ctx.hasUI) return;

  if (!process.stdin.isTTY || !process.stderr.isTTY) {
    ctx.ui.notify("search-prompts requires an interactive terminal.", "warning");
    return;
  }

  if (!ctx.isIdle()) {
    ctx.ui.notify("Prompt search is available when pi is idle.", "warning");
    return;
  }

  if (!fzfAvailable()) {
    ctx.ui.notify("search-prompts requires fzf on PATH.", "error");
    return;
  }

  ctx.ui.setStatus("search-prompts", "loading prompt history…");
  let records: PromptRecord[];
  try {
    records = await collectPromptHistory(ctx);
  } catch (error) {
    ctx.ui.setStatus("search-prompts", undefined);
    ctx.ui.notify(
      `Could not load prompt history: ${error instanceof Error ? error.message : String(error)}`,
      "error",
    );
    return;
  }
  ctx.ui.setStatus("search-prompts", undefined);

  if (records.length === 0) {
    ctx.ui.notify("No past prompts found.", "info");
    return;
  }

  const result = await runFzf(records, ctx, initialQuery);

  if (result.error) {
    ctx.ui.notify(`Prompt search failed: ${result.error}`, "error");
    return;
  }

  if (result.prompt !== undefined) {
    ctx.ui.setEditorText(result.prompt);
    ctx.ui.notify("Prompt restored into the input editor.", "info");
  }
}

export default function searchPrompts(pi: ExtensionAPI) {
  let searchOpen = false;

  async function guardedOpen(ctx: ExtensionContext, initialQuery = ""): Promise<void> {
    if (searchOpen) return;
    searchOpen = true;
    try {
      await openPromptSearch(ctx, initialQuery);
    } finally {
      searchOpen = false;
    }
  }

  pi.registerShortcut("ctrl+r", {
    description: "Search past prompts",
    handler: async (ctx) => {
      await guardedOpen(ctx);
    },
  });

  pi.registerCommand("search-prompts", {
    description: "Search past prompts with fzf and restore one into the input editor",
    handler: async (args, ctx) => {
      await guardedOpen(ctx, args);
    },
  });
}
