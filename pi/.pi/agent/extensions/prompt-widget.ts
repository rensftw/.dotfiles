import type {
  ExtensionAPI,
  ExtensionContext,
  SessionEntry,
  Theme,
} from "@earendil-works/pi-coding-agent";
import {
  truncateToWidth,
  visibleWidth,
  wrapTextWithAnsi,
  type TUI,
} from "@earendil-works/pi-tui";

const WIDGET_ID = "prompt-widget";
const MAX_PROMPT_LINES = 3;

type PromptMode = "visible" | "root";

interface RenderableLike {
  render?(width: number): string[];
  children?: unknown[];
  text?: unknown;
}

interface ScrollViewLike {
  scrollTop: number;
  contentHeight?: number;
  child?: unknown;
  getContentWidth(width: number): number;
}

type TuiInternals = TUI & {
  getPrimaryScrollView?: () => ScrollViewLike | undefined;
};

interface PromptEntry {
  start: number;
  text: string;
}

interface PromptIndexCache {
  width: number;
  contentHeight: number | undefined;
  entries: PromptEntry[];
}

function collapsePrompt(text: string): string {
  return text.replace(/\s+/gu, " ").trim();
}

function contentText(content: unknown): string {
  if (typeof content === "string") return collapsePrompt(content);
  if (!Array.isArray(content)) return "";

  return collapsePrompt(
    content
      .map((block) => {
        if (typeof block !== "object" || block === null) return "";
        const { type, text } = block as { type?: unknown; text?: unknown };
        return type === "text" && typeof text === "string" ? text : "";
      })
      .join(" "),
  );
}

function userPromptText(entry: SessionEntry): string {
  if (entry.type !== "message" || entry.message.role !== "user") return "";
  return contentText(entry.message.content);
}

function firstUserPrompt(entries: readonly SessionEntry[]): string {
  for (const entry of entries) {
    const prompt = userPromptText(entry);
    if (prompt) return prompt;
  }
  return "";
}

function lastUserPrompt(entries: readonly SessionEntry[]): string {
  for (let index = entries.length - 1; index >= 0; index -= 1) {
    const prompt = userPromptText(entries[index]!);
    if (prompt) return prompt;
  }
  return "";
}

function componentName(component: unknown): string {
  return (component as { constructor?: { name?: string } })?.constructor?.name ?? "";
}

function renderedHeight(component: RenderableLike, width: number): number {
  try {
    return component.render?.(width).length ?? 0;
  } catch {
    return 0;
  }
}

/** Collect user-message offsets from Pi's fullscreen transcript component tree. */
function collectPromptEntries(
  children: unknown[],
  width: number,
  offset: number,
  entries: PromptEntry[],
): number {
  for (const child of children) {
    const component = child as RenderableLike;
    const name = componentName(child);

    if (name === "UserMessageComponent") {
      if (typeof component.text === "string") {
        const text = collapsePrompt(component.text);
        if (text) entries.push({ start: offset, text });
      }
      offset += renderedHeight(component, width);
      continue;
    }

    // Plain Containers concatenate their children, so their rendered heights
    // can be accumulated without introducing layout offsets.
    if (name === "Container" && Array.isArray(component.children)) {
      offset = collectPromptEntries(component.children, width, offset, entries);
      continue;
    }

    offset += renderedHeight(component, width);
  }

  return offset;
}

function padStyled(text: string, width: number): string {
  const clipped = truncateToWidth(text, width, "…");
  return clipped + " ".repeat(Math.max(0, width - visibleWidth(clipped)));
}

function renderPromptWidget(
  mode: PromptMode,
  prompt: string,
  width: number,
  theme: Theme,
): string[] {
  if (width < 4) return [];

  const innerWidth = width - 2;
  const contentWidth = Math.max(1, innerWidth - 2);
  const label = mode === "visible" ? "LATEST PROMPT" : "ROOT PROMPT";
  const shortcut = mode === "visible" ? "ctrl+p" : "ctrl+shift+p";
  const border = (text: string) => theme.fg("borderAccent", text);
  const background = (text: string) => theme.bg("selectedBg", text);

  const rawPrompt = prompt || "No user prompt in this session yet.";
  const wrapped = wrapTextWithAnsi(rawPrompt, contentWidth);
  const shown = wrapped.slice(0, MAX_PROMPT_LINES);
  if (wrapped.length > MAX_PROMPT_LINES && shown.length > 0) {
    shown[shown.length - 1] = truncateToWidth(
      `${shown[shown.length - 1]}…`,
      contentWidth,
      "…",
    );
  }

  const labelText = ` ${label}`;
  const hintText = `${shortcut} hide `;
  const availableGap = innerWidth - visibleWidth(labelText) - visibleWidth(hintText);
  const header = availableGap >= 1
    ? `${theme.fg("accent", theme.bold(labelText))}${" ".repeat(availableGap)}${theme.fg("muted", hintText)}`
    : theme.fg("accent", theme.bold(padStyled(labelText, innerWidth)));

  const lines = [border(`╭${"─".repeat(innerWidth)}╮`)];
  lines.push(`${border("│")}${background(padStyled(header, innerWidth))}${border("│")}`);

  for (const line of shown) {
    const content = ` ${theme.fg("text", line)}`;
    lines.push(`${border("│")}${background(padStyled(content, innerWidth))}${border("│")}`);
  }

  lines.push(border(`╰${"─".repeat(innerWidth)}╯`));
  return lines;
}

export default function promptWidgetExtension(pi: ExtensionAPI): void {
  let mode: PromptMode | undefined;
  let rootPrompt = "";
  let latestPrompt = "";
  let widgetTui: TUI | undefined;
  let promptIndexCache: PromptIndexCache | undefined;
  let warnedAboutRegularMode = false;

  function resetState(): void {
    mode = undefined;
    rootPrompt = "";
    latestPrompt = "";
    widgetTui = undefined;
    promptIndexCache = undefined;
    warnedAboutRegularMode = false;
  }

  function refreshSessionPrompts(ctx: ExtensionContext): void {
    const branch = ctx.sessionManager.getBranch();
    rootPrompt = firstUserPrompt(branch);
    latestPrompt = lastUserPrompt(branch);
    promptIndexCache = undefined;
  }

  function visiblePrompt(tui: TUI, widgetWidth: number): string {
    if (tui.mode !== "fullscreen") return latestPrompt;

    const scrollView = (tui as TuiInternals).getPrimaryScrollView?.();
    if (!scrollView) return latestPrompt;

    const document = scrollView.child as RenderableLike | undefined;
    if (!document || !Array.isArray(document.children)) return latestPrompt;

    const contentWidth = scrollView.getContentWidth(Math.max(1, widgetWidth));
    if (
      !promptIndexCache ||
      promptIndexCache.width !== contentWidth ||
      promptIndexCache.contentHeight !== scrollView.contentHeight
    ) {
      const entries: PromptEntry[] = [];
      collectPromptEntries(document.children, contentWidth, 0, entries);
      promptIndexCache = {
        width: contentWidth,
        contentHeight: scrollView.contentHeight,
        entries,
      };
    }

    const entries = promptIndexCache.entries;
    if (entries.length === 0) return latestPrompt;

    let current = entries[0]!;
    for (const entry of entries) {
      if (entry.start > scrollView.scrollTop) break;
      current = entry;
    }
    return current.text;
  }

  function applyWidget(ctx: ExtensionContext): void {
    if (ctx.mode !== "tui") return;

    if (!mode) {
      if (widgetTui) ctx.ui.setWidget(WIDGET_ID, undefined);
      widgetTui = undefined;
      promptIndexCache = undefined;
      return;
    }

    if (!widgetTui) {
      ctx.ui.setWidget(
        WIDGET_ID,
        (tui, theme) => {
          widgetTui = tui;
          return {
            render(width: number): string[] {
              if (!mode) return [];
              const prompt = mode === "root"
                ? rootPrompt
                : visiblePrompt(tui, width);
              return renderPromptWidget(mode, prompt, width, theme);
            },
            invalidate(): void {
              promptIndexCache = undefined;
            },
            dispose(): void {
              if (widgetTui === tui) widgetTui = undefined;
            },
          };
        },
        { placement: "aboveEditor" },
      );
    }

    widgetTui?.requestRender();
  }

  function toggle(nextMode: PromptMode, ctx: ExtensionContext): void {
    // Resolve prompts at keypress time so branch navigation is reflected even
    // if the widget was hidden while the active leaf changed.
    refreshSessionPrompts(ctx);
    mode = mode === nextMode ? undefined : nextMode;
    applyWidget(ctx);

    if (
      mode === "visible" &&
      widgetTui?.mode === "regular" &&
      !warnedAboutRegularMode
    ) {
      warnedAboutRegularMode = true;
      ctx.ui.notify(
        "Visible-prompt tracking follows the latest prompt in regular mode. Use fullscreen mode for scroll-aware transcript tracking.",
        "info",
      );
    }
  }

  pi.registerShortcut("ctrl+p", {
    description: "Toggle prompt for the visible transcript section",
    handler: (ctx) => toggle("visible", ctx),
  });

  pi.registerShortcut("ctrl+shift+p", {
    description: "Toggle the root prompt from the active branch",
    handler: (ctx) => toggle("root", ctx),
  });

  pi.on("before_agent_start", (event, ctx) => {
    // Runs started by pi.sendMessage(..., { triggerTurn: true }) carry a custom message, not a prompt.
    if (event.messageType !== "user") return;
    const prompt = collapsePrompt(event.prompt);
    if (!prompt) return;

    latestPrompt = prompt;
    if (!rootPrompt) {
      rootPrompt = firstUserPrompt(ctx.sessionManager.getBranch()) || prompt;
    }
    promptIndexCache = undefined;
    widgetTui?.requestRender();
  });

  pi.on("session_start", (_event, ctx) => {
    resetState();
    refreshSessionPrompts(ctx);
  });

  pi.on("session_tree", (_event, ctx) => {
    refreshSessionPrompts(ctx);
    applyWidget(ctx);
  });

  pi.on("session_shutdown", (_event, ctx) => {
    if (ctx.mode === "tui") ctx.ui.setWidget(WIDGET_ID, undefined);
    resetState();
  });
}
