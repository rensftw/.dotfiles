import type {
  ExtensionAPI,
  ExtensionContext,
  ReadonlyFooterDataProvider,
  Theme,
  ThemeColor,
} from "@earendil-works/pi-coding-agent";
import type { TUI } from "@earendil-works/pi-tui";
import { rgbColor, truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

const PI_CORAL = rgbColor(228, 138, 122);
const THINKING_COLOR: Record<string, ThemeColor> = {
  off: "thinkingOff",
  minimal: "thinkingMinimal",
  low: "thinkingLow",
  medium: "thinkingMedium",
  high: "thinkingHigh",
  xhigh: "thinkingXhigh",
  max: "thinkingMax",
};

function formatDuration(milliseconds: number, compact = false): string {
  const total = Math.max(0, Math.round(milliseconds / 1000));
  const hours = Math.floor(total / 3600);
  const minutes = Math.floor((total % 3600) / 60);
  const seconds = total % 60;
  const gap = compact ? "" : " ";

  if (hours) return `${hours}h${gap}${minutes}m${gap}${seconds}s`;
  if (minutes) return `${minutes}m${gap}${seconds}s`;
  return `${seconds}s`;
}

function formatTokens(tokens: number): string {
  if (tokens < 1_000) return `${tokens}`;
  if (tokens < 10_000) return `${(tokens / 1_000).toFixed(1)}k`;
  if (tokens < 1_000_000) return `${Math.round(tokens / 1_000)}k`;
  if (tokens < 10_000_000) return `${(tokens / 1_000_000).toFixed(1)}M`;
  return `${Math.round(tokens / 1_000_000)}M`;
}

function calculateCost(ctx: ExtensionContext): number {
  let total = 0;
  for (const entry of ctx.sessionManager.getEntries()) {
    if (entry.type === "usage") {
      total += entry.usage.cost.total;
    } else if (entry.type === "message") {
      if (entry.message.role === "assistant") total += entry.message.usage.cost.total;
      if (entry.message.role === "toolResult" && entry.message.usage) {
        total += entry.message.usage.cost.total;
      }
    } else if (
      (entry.type === "branch_summary" || entry.type === "compaction") &&
      entry.usage
    ) {
      total += entry.usage.cost.total;
    }
  }
  return total;
}

function isSubscription(ctx: ExtensionContext): boolean {
  const model = ctx.model;
  if (!model) return false;
  if (model.provider === "kimi-coding") return true;

  return Boolean(
    ctx.modelRegistry.getProvider(model.provider)?.auth.oauth?.isSubscription &&
    ctx.modelRegistry.isUsingOAuth(model),
  );
}

function renderContext(ctx: ExtensionContext, theme: Theme): string {
  const usage = ctx.getContextUsage();
  const percent = usage?.percent ?? null;
  const window = usage?.contextWindow ?? ctx.model?.contextWindow;
  const text = `${percent === null ? "?" : `${percent.toFixed(1)}%`}/${
    window ? formatTokens(window) : "—"
  }`;
  const color: ThemeColor = percent === null
    ? "muted"
    : percent > 90
    ? "error"
    : percent > 70
    ? "warning"
    : "text";
  return theme.fg(color, text);
}

function renderModel(ctx: ExtensionContext, theme: Theme, maxWidth?: number): string {
  const model = ctx.model?.id ?? "no-model";
  const level = ctx.model?.reasoning ? (ctx.thinkingLevel ?? "off") : "off";
  const suffix = ` · ${level} `;
  let text = ` ${model}${suffix}`;

  if (maxWidth !== undefined && visibleWidth(text) > maxWidth) {
    const modelWidth = maxWidth - visibleWidth(suffix) - 1;
    text = modelWidth > 1
      ? ` ${truncateToWidth(model, modelWidth, "…")}${suffix}`
      : truncateToWidth(text, maxWidth, "…");
  }

  return theme.style(text, {
    fg: THINKING_COLOR[level] ?? "thinkingOff",
    inverse: true,
    bold: true,
  });
}

function align(left: string, right: string, width: number): string | undefined {
  const gap = width - visibleWidth(left) - visibleWidth(right);
  return gap >= 2 ? `${left}${" ".repeat(gap)}${right}` : undefined;
}

function renderStatuses(
  footerData: ReadonlyFooterDataProvider,
  theme: Theme,
  width: number,
): string | undefined {
  const statuses = [...footerData.getExtensionStatuses()]
    .sort(([a], [b]) => a.localeCompare(b))
    .map(([, text]) => text.replace(/[\r\n\t]+/g, " ").replace(/ +/g, " ").trim())
    .filter(Boolean)
    .join("  ");

  return statuses
    ? truncateToWidth(theme.fg("dim", statuses), width, theme.fg("dim", "…"))
    : undefined;
}

export default function customFooter(pi: ExtensionAPI): void {
  let tui: TUI | undefined;
  let startedAt: number | undefined;
  let lastDuration: number | undefined;
  let costLeaf: string | null | undefined;
  let cost = 0;

  pi.on("session_start", (_event, ctx) => {
    startedAt = undefined;
    lastDuration = undefined;
    costLeaf = undefined;
    if (ctx.mode !== "tui") return;

    ctx.ui.setFooter((nextTui, theme, footerData) => {
      tui = nextTui;

      return {
        invalidate() {},
        dispose() {
          if (tui === nextTui) tui = undefined;
        },
        render(width: number): string[] {
          if (width < 1) return [];

          const leaf = ctx.sessionManager.getLeafId();
          if (leaf !== costLeaf) {
            costLeaf = leaf;
            cost = calculateCost(ctx);
          }

          const wideDuration = lastDuration === undefined
            ? "—"
            : formatDuration(lastDuration);
          const compactDuration = lastDuration === undefined
            ? "—"
            : formatDuration(lastDuration, true);
          const context = renderContext(ctx, theme);
          const costText = theme.fg("text", `$${cost.toFixed(3)}`);
          const subscribed = isSubscription(ctx);
          const logo = theme.style("  ", { fg: PI_CORAL, bold: true });
          const firstDivider = theme.fg("dim", "· ");
          const dot = theme.fg("dim", " · ");
          const pipe = theme.fg("dim", " │ ");

          const wide = [
            logo,
            firstDivider,
            theme.fg("text", wideDuration),
            dot,
            theme.fg("dim", "ctx "),
            context,
            dot,
            theme.fg("dim", "cost "),
            costText,
            subscribed ? ` ${theme.fg("muted", "(sub)")}` : "",
          ].join("");
          const compact = [
            logo,
            firstDivider,
            theme.fg("text", compactDuration),
            pipe,
            theme.fg("dim", "ctx "),
            context,
            pipe,
            costText,
            subscribed ? ` ${theme.fg("muted", "sub")}` : "",
          ].join("");

          const model = renderModel(ctx, theme);
          const singleLine = align(wide, model, width) ?? align(compact, model, width);
          const narrowModel = renderModel(ctx, theme, width);
          const lines = singleLine
            ? [singleLine]
            : [
                truncateToWidth(compact, width, theme.fg("dim", "…")),
                `${" ".repeat(Math.max(0, width - visibleWidth(narrowModel)))}${narrowModel}`,
              ];

          const statuses = renderStatuses(footerData, theme, width);
          if (statuses) lines.push(statuses);
          return lines;
        },
      };
    });
  });

  pi.on("agent_start", () => {
    startedAt ??= performance.now();
  });

  pi.on("agent_settled", () => {
    if (startedAt !== undefined) {
      lastDuration = performance.now() - startedAt;
      startedAt = undefined;
    }
    tui?.requestRender();
  });

  pi.on("session_shutdown", (_event, ctx) => {
    if (ctx.mode === "tui") ctx.ui.setFooter(undefined);
    tui = undefined;
    startedAt = undefined;
  });
}
