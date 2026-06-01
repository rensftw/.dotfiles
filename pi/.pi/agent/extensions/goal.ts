import type {
  ExtensionAPI,
  ExtensionCommandContext,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { completeSimple, type Api, type Model, type Usage } from "@earendil-works/pi-ai";
import { truncateToWidth, type Component, type TUI } from "@earendil-works/pi-tui";

const CUSTOM_TYPE = "goal-state-v1";

const DISMISS_WORDS = new Set([
  "clear",
  "stop",
  "end",
  "abort",
  "dismiss",
  "dismissed",
  "dismisss",
  "hide",
  "close",
  "remove",
  "finish",
  "finished",
  "off",
  "reset",
  "none",
  "cancel",
]);

const STATUS_WORDS = new Set(["status", "show", "info", "inspect"]);

const INTERRUPT_WORDS = new Set(["abort", "cancel", "end", "finish", "finished", "off", "reset", "stop"]);
const SHORT_CONDITION_MAX_CHARS = 28;

type GoalPhase = "active" | "done";
type GoalColor = "accent" | "success" | "warning" | "muted";

type PersistedGoal =
  | { type: "goal"; state: GoalState }
  | { type: "dismissed" };

type RestoreResult =
  | { kind: "goal"; state: GoalState }
  | { kind: "dismissed" }
  | { kind: "ignore" };

interface GoalVerdict {
  met: boolean;
  reasoning: string;
  evaluatorModel?: string;
  evaluatedAt: number;
  error?: string;
}

interface GoalUsage {
  tokens: number;
  cost: number;
}

interface GoalState {
  phase: GoalPhase;
  condition: string;
  startedAt: number;
  startEntryId: string | null;
  turnCount: number;
  evaluationUsage: GoalUsage;
  shortCondition?: string;
  latestVerdict?: GoalVerdict;
  endedAt?: number;
  finalUsage?: GoalUsage;
}

interface PendingGoalStart {
  id: number;
  condition: string;
}

interface SessionEntry {
  type?: string;
  id?: string;
  customType?: string;
  data?: unknown;
  message?: unknown;
}

interface MessageEntry extends SessionEntry {
  type: "message";
  message: unknown;
}

interface GoalDisplay {
  icon: string;
  label: string;
  color: GoalColor;
  turns: string;
  spent: string;
  elapsed: string;
  condition: string;
}

/** Return true when a value is a non-null object with string keys. */
function isRecord(value: unknown): value is Record<string, unknown> {
  return !!value && typeof value === "object";
}

/** Return true when a session entry contains a message payload. */
function isMessageEntry(entry: SessionEntry): entry is MessageEntry {
  return entry.type === "message" && "message" in entry;
}

/** Normalize a possibly malformed/persisted usage object into goal usage totals. */
function normalizeUsage(value: unknown): GoalUsage {
  if (!isRecord(value)) return { tokens: 0, cost: 0 };
  return {
    tokens: typeof value.tokens === "number" ? value.tokens : 0,
    cost: typeof value.cost === "number" ? value.cost : 0,
  };
}

/** Normalize optional persisted usage, preserving undefined when no total was saved. */
function normalizeOptionalUsage(value: unknown): GoalUsage | undefined {
  return isRecord(value) ? normalizeUsage(value) : undefined;
}

/** Normalize a persisted verdict object, dropping invalid optional verdict data. */
function normalizeVerdict(value: unknown): GoalVerdict | undefined {
  if (!isRecord(value)) return undefined;
  if (
    typeof value.met !== "boolean" ||
    typeof value.reasoning !== "string" ||
    typeof value.evaluatedAt !== "number"
  ) {
    return undefined;
  }

  return {
    met: value.met,
    reasoning: value.reasoning,
    evaluatedAt: value.evaluatedAt,
    evaluatorModel: typeof value.evaluatorModel === "string" ? value.evaluatorModel : undefined,
    error: typeof value.error === "string" ? value.error : undefined,
  };
}

/** Convert current and legacy persisted state shapes into the current GoalState shape. */
function normalizeGoalState(value: unknown): GoalState | undefined {
  if (!isRecord(value)) return undefined;
  if (typeof value.condition !== "string" || typeof value.startedAt !== "number") return undefined;

  let phase: GoalPhase | undefined;
  if (value.phase === "active" || value.phase === "done") phase = value.phase;
  else if (value.active === true) phase = "active";
  else if (value.active === false) phase = "done";
  if (!phase) return undefined;

  const startEntryId = typeof value.startEntryId === "string" || value.startEntryId === null
    ? value.startEntryId
    : null;
  const endedAt = typeof value.endedAt === "number"
    ? value.endedAt
    : typeof value.completedAt === "number"
      ? value.completedAt
      : undefined;

  const shortCondition = sanitizeShortCondition(value.shortCondition);

  return {
    phase,
    condition: value.condition,
    startedAt: value.startedAt,
    startEntryId,
    turnCount: typeof value.turnCount === "number" ? value.turnCount : 0,
    evaluationUsage: normalizeUsage(value.evaluationUsage ?? value.evaluatorUsage),
    shortCondition,
    latestVerdict: normalizeVerdict(value.latestVerdict),
    endedAt,
    finalUsage: normalizeOptionalUsage(value.finalUsage ?? value.completedUsage),
  };
}

/** Decode a custom session entry and handle legacy dismissed entries. */
function restoreGoalEntry(data: unknown): RestoreResult {
  if (!isRecord(data)) return { kind: "ignore" };

  if (data.type === "dismissed") return { kind: "dismissed" };

  if (data.type === "goal") {
    const state = normalizeGoalState(data.state);
    return state ? { kind: "goal", state } : { kind: "ignore" };
  }

  if (data.active === false && typeof data.condition !== "string") {
    return { kind: "dismissed" };
  }

  const state = normalizeGoalState(data);
  return state ? { kind: "goal", state } : { kind: "ignore" };
}

/** Format a millisecond duration into a compact human-readable string. */
function formatDuration(ms: number): string {
  const totalSeconds = Math.max(0, Math.floor(ms / 1000));
  const hours = Math.floor(totalSeconds / 3600);
  const minutes = Math.floor((totalSeconds % 3600) / 60);
  const seconds = totalSeconds % 60;

  if (hours > 0) return `${hours}h ${minutes}m ${seconds}s`;
  if (minutes > 0) return `${minutes}m ${seconds}s`;
  return `${seconds}s`;
}

/** Format model spend in dollars while preserving useful precision for detailed views. */
function money(amount: number): string {
  if (!Number.isFinite(amount) || amount <= 0) return "$0.0000";
  if (amount < 0.01) return `$${amount.toFixed(5)}`;
  return `$${amount.toFixed(4)}`;
}

/** Format model spend compactly for the one-line widget, capped at 3 decimals. */
function compactMoney(amount: number): string {
  if (!Number.isFinite(amount) || amount <= 0) return "$0";
  if (amount < 0.001) return "<$0.001";
  return `$${amount.toFixed(3).replace(/\.?0+$/, "")}`;
}

/** Normalize provider usage into the small token/cost shape tracked by /goal. */
function usageTotals(usage?: Usage): GoalUsage {
  return {
    tokens: usage?.totalTokens ?? 0,
    cost: usage?.cost?.total ?? 0,
  };
}

/** Add two usage totals without mutating either input. */
function addUsage(a: GoalUsage, b: GoalUsage): GoalUsage {
  return {
    tokens: a.tokens + b.tokens,
    cost: a.cost + b.cost,
  };
}

/** Combine abort signals so either Pi cancellation or /goal stop cancels evaluator work. */
function combinedAbortSignal(...signals: Array<AbortSignal | undefined>): AbortSignal | undefined {
  const active = signals.filter((signal): signal is AbortSignal => !!signal);
  if (active.length === 0) return undefined;
  if (active.length === 1) return active[0];

  const abortSignal = AbortSignal as typeof AbortSignal & { any?: (signals: AbortSignal[]) => AbortSignal };
  if (abortSignal.any) return abortSignal.any(active);

  const controller = new AbortController();
  const abort = () => controller.abort();
  for (const signal of active) {
    if (signal.aborted) {
      controller.abort();
      break;
    }
    signal.addEventListener("abort", abort, { once: true });
  }
  return controller.signal;
}

/** Best-effort JSON stringify for tool-call arguments in evaluator transcripts. */
function safeJson(value: unknown): string {
  try {
    return JSON.stringify(value ?? {});
  } catch {
    return "{}";
  }
}

/** Extract evaluator/transcript-relevant text from a Pi or pi-ai message object. */
function messageText(message: unknown): string {
  if (!isRecord(message)) return "";

  const { content } = message;
  if (typeof content === "string") return content;
  if (!Array.isArray(content)) return "";

  return content
    .map((rawPart) => {
      if (!isRecord(rawPart)) return "";

      if (rawPart.type === "text") return typeof rawPart.text === "string" ? rawPart.text : "";
      if (rawPart.type === "thinking") return "";
      if (rawPart.type === "toolCall") {
        const name = typeof rawPart.name === "string" ? rawPart.name : "tool";
        return `[tool call: ${name} ${safeJson(rawPart.arguments)}]`;
      }
      if (rawPart.type === "image") return "[image]";
      return "";
    })
    .filter(Boolean)
    .join("\n");
}

/** Truncate long evaluator transcripts while preserving both beginning and ending context. */
function truncateMiddle(text: string, maxChars: number): string {
  if (text.length <= maxChars) return text;
  const head = Math.floor(maxChars * 0.45);
  const tail = Math.floor(maxChars * 0.45);
  return `${text.slice(0, head)}\n\n[... ${text.length - head - tail} characters omitted ...]\n\n${text.slice(-tail)}`;
}

/** Return message entries on the active branch after the goal was created. */
function branchSinceGoal(ctx: ExtensionContext | ExtensionCommandContext, state: GoalState): MessageEntry[] {
  const branch = ctx.sessionManager.getBranch() as SessionEntry[];
  const startIndex = state.startEntryId
    ? branch.findIndex((entry) => entry.id === state.startEntryId)
    : -1;
  const afterStart = startIndex >= 0 ? branch.slice(startIndex + 1) : branch;

  return afterStart.filter(isMessageEntry);
}

/** Build the bounded transcript sent to the evaluator model. */
function transcriptSinceGoal(ctx: ExtensionContext | ExtensionCommandContext, state: GoalState): string {
  const lines: string[] = [];

  for (const entry of branchSinceGoal(ctx, state).slice(-50)) {
    const message = isRecord(entry.message) ? entry.message : {};
    const role = typeof message.role === "string" ? message.role : "unknown";
    const text = messageText(message).trim();
    if (!text) continue;

    const label = role === "toolResult"
      ? `toolResult:${typeof message.toolName === "string" ? message.toolName : "tool"}${message.isError ? " (error)" : ""}`
      : role;
    lines.push(`## ${label}\n${text}`);
  }

  return truncateMiddle(lines.join("\n\n"), 60_000);
}

/** Sum assistant model usage attributable to work performed since the goal started. */
function agentUsageSinceGoal(ctx: ExtensionContext | ExtensionCommandContext, state: GoalState): GoalUsage {
  return branchSinceGoal(ctx, state).reduce(
    (total, entry) => {
      const message = isRecord(entry.message) ? entry.message : {};
      const usage = message.role === "assistant" ? (message.usage as Usage | undefined) : undefined;
      return addUsage(total, usageTotals(usage));
    },
    { tokens: 0, cost: 0 },
  );
}

/** Compute total goal spend, including evaluator usage and frozen completed-goal totals. */
function totalSpend(ctx: ExtensionContext | ExtensionCommandContext, state: GoalState): GoalUsage {
  if (state.phase === "done" && state.finalUsage) return state.finalUsage;
  return addUsage(agentUsageSinceGoal(ctx, state), state.evaluationUsage);
}

/** Parse a JSON object from strict JSON, fenced JSON, or a loose object substring. */
function parseJsonObject(text: string): Record<string, unknown> | undefined {
  const trimmed = text.trim();

  for (const candidate of [
    trimmed,
    trimmed.match(/```(?:json)?\s*([\s\S]*?)\s*```/i)?.[1],
    trimmed.match(/\{[\s\S]*\}/)?.[0],
  ]) {
    if (!candidate) continue;
    try {
      const parsed = JSON.parse(candidate);
      if (isRecord(parsed)) return parsed;
    } catch {}
  }

  return undefined;
}

/** Recover a verdict from non-JSON evaluator output when it still names met=true/false. */
function parseLooseVerdict(text: string): { met: boolean; reasoning: string } | undefined {
  const trimmed = text.trim();
  if (!trimmed) return undefined;

  const metMatch = trimmed.match(/\bmet\b\s*[:=]\s*(true|false|yes|no)\b/i);
  if (!metMatch) return undefined;

  const value = metMatch[1].toLowerCase();
  const reasoningMatch = trimmed.match(/\breasoning\b\s*[:=]\s*([\s\S]*)/i);

  return {
    met: value === "true" || value === "yes",
    reasoning: reasoningMatch?.[1]?.trim() || trimmed,
  };
}

/** Render a model as provider/id for storage, display, and exact matching. */
function modelKey(model: Model<Api>): string {
  return `${model.provider}/${model.id}`;
}

/** Find an available model by either id or provider/id spec. */
function findBySpec(models: Model<Api>[], spec: string): Model<Api> | undefined {
  const normalized = spec.trim();
  if (!normalized) return undefined;

  const slash = normalized.indexOf("/");
  if (slash > 0) {
    const provider = normalized.slice(0, slash);
    const id = normalized.slice(slash + 1);
    return models.find((model) => model.provider === provider && model.id === id);
  }

  return models.find((model) => model.id === normalized || modelKey(model) === normalized);
}

/** Choose a cheap/fast authenticated-capable model to evaluate goal completion. */
function chooseEvaluatorModel(ctx: ExtensionContext | ExtensionCommandContext): Model<Api> | undefined {
  const available = ctx.modelRegistry.getAvailable();
  const requested = process.env.PI_GOAL_MODEL;
  if (requested) {
    const model = findBySpec(available, requested);
    if (model) return model;
  }

  const currentProvider = ctx.model?.provider;
  const preferredIds = [
    "claude-haiku-4-5",
    "claude-haiku-4.5",
    "claude-3-5-haiku-latest",
    "claude-3-5-haiku-20241022",
    "gpt-5.4-mini",
    "gpt-5-mini",
    "gpt-5-nano",
    "gpt-4.1-mini",
    "o4-mini",
    "gemini-flash-lite-latest",
    "gemini-3.1-flash-lite",
    "gemini-3-flash-preview",
    "gemini-2.5-flash-lite",
    "gemini-2.5-flash",
  ];

  if (currentProvider) {
    for (const id of preferredIds) {
      const model = available.find((candidate) => candidate.provider === currentProvider && candidate.id === id);
      if (model) return model;
    }

    const sameProviderFast = available.find(
      (model) => model.provider === currentProvider && /(?:haiku|mini|nano|flash|lite|spark)/i.test(model.id),
    );
    if (sameProviderFast) return sameProviderFast;
  }

  for (const spec of [
    "anthropic/claude-haiku-4-5",
    "anthropic/claude-3-5-haiku-latest",
    "openai-codex/gpt-5.4-mini",
    "openai/gpt-5-mini",
    "openai/gpt-5-nano",
    "google/gemini-flash-lite-latest",
    "google/gemini-3.1-flash-lite",
    "google/gemini-3-flash-preview",
    "github-copilot/claude-haiku-4.5",
    "github-copilot/gpt-5-mini",
    "github-copilot/gemini-3-flash-preview",
  ]) {
    const model = findBySpec(available, spec);
    if (model) return model;
  }

  return ctx.model && ctx.modelRegistry.hasConfiguredAuth(ctx.model) ? ctx.model : available[0];
}

/** Ask the evaluator model whether the current transcript satisfies the goal. */
async function evaluateGoal(
  ctx: ExtensionContext | ExtensionCommandContext,
  state: GoalState,
  signal?: AbortSignal,
): Promise<GoalVerdict> {
  const model = chooseEvaluatorModel(ctx);
  if (!model) {
    return {
      met: false,
      reasoning:
        "No authenticated evaluator model is available. Set PI_GOAL_MODEL=provider/model or configure a fast model provider.",
      evaluatedAt: Date.now(),
      error: "no-evaluator-model",
    };
  }

  const auth = await ctx.modelRegistry.getApiKeyAndHeaders(model);
  if (!auth.ok) {
    return {
      met: false,
      reasoning: `Evaluator model ${modelKey(model)} is not authenticated: ${auth.error}`,
      evaluatorModel: modelKey(model),
      evaluatedAt: Date.now(),
      error: auth.error,
    };
  }

  const transcript = transcriptSinceGoal(ctx, state) || "[No conversation entries since the goal was set.]";
  const response = await completeSimple(
    model,
    {
      systemPrompt: [
        "You are Pi's /goal completion evaluator.",
        "Decide whether the completion condition is satisfied by the transcript.",
        "Be strict: return met=true only when there is clear, current evidence in the transcript.",
        "For tests/lint/build goals, passing command output or an equivalent explicit result is required.",
        "If evidence is absent, stale, contradicted, or the agent merely claims success without proof, return met=false.",
        "Return only JSON in this exact shape: {\"met\": boolean, \"reasoning\": string}.",
      ].join("\n"),
      messages: [
        {
          role: "user",
          timestamp: Date.now(),
          content: [
            "Completion condition:",
            state.condition,
            "",
            "Transcript since the goal was set, oldest to newest:",
            transcript,
          ].join("\n"),
        },
      ],
    },
    {
      apiKey: auth.apiKey,
      headers: auth.headers,
      maxTokens: 1200,
      // Some evaluator candidates reject non-default temperature.
      reasoning: "minimal",
      signal: signal ?? ctx.signal,
    },
  );

  state.evaluationUsage = addUsage(state.evaluationUsage, usageTotals(response.usage));

  if (response.stopReason === "error" || response.stopReason === "aborted" || response.errorMessage) {
    return {
      met: false,
      reasoning: `Evaluator ${modelKey(model)} failed with stopReason=${response.stopReason}${
        response.errorMessage ? `: ${response.errorMessage}` : ""
      }`,
      evaluatorModel: modelKey(model),
      evaluatedAt: Date.now(),
      error: "evaluator-response-error",
    };
  }

  const text = messageText(response).trim();
  const parsed = parseJsonObject(text);
  const loose = parsed ? undefined : parseLooseVerdict(text);

  if (!parsed && !loose) {
    return {
      met: false,
      reasoning: text
        ? `Evaluator ${modelKey(model)} did not return the required JSON verdict. Raw response: ${truncateMiddle(text, 1000)}`
        : `Evaluator ${modelKey(model)} returned no text (stopReason=${response.stopReason}).`,
      evaluatorModel: modelKey(model),
      evaluatedAt: Date.now(),
      error: "invalid-evaluator-verdict",
    };
  }

  const met = parsed ? parsed.met === true : loose!.met;
  const reasoning = parsed
    ? typeof parsed.reasoning === "string" && parsed.reasoning.trim()
      ? parsed.reasoning.trim()
      : text
    : loose!.reasoning;

  return {
    met,
    reasoning,
    evaluatorModel: modelKey(model),
    evaluatedAt: Date.now(),
  };
}

/** Ask the evaluator model for a tiny terminal-widget label for the goal condition. */
async function generateShortCondition(
  ctx: ExtensionContext | ExtensionCommandContext,
  state: GoalState,
  signal?: AbortSignal,
): Promise<string | undefined> {
  const model = chooseEvaluatorModel(ctx);
  if (!model) return undefined;

  const auth = await ctx.modelRegistry.getApiKeyAndHeaders(model);
  if (!auth.ok || signal?.aborted) return undefined;

  const response = await completeSimple(
    model,
    {
      systemPrompt: [
        "You write compact labels for Pi's /goal terminal widget.",
        `Return a short, specific label of at most ${SHORT_CONDITION_MAX_CHARS} visible characters.`,
        "Prefer 2-4 plain words. Keep the key action and object.",
        "Do not include words like goal, task, condition, status, done, active, or checking.",
        "Do not add quotes, trailing punctuation, emoji, markdown, or explanations.",
        "Return only JSON in this exact shape: {\"label\": string}.",
      ].join("\n"),
      messages: [
        {
          role: "user",
          timestamp: Date.now(),
          content: `Goal condition:\n${state.condition}`,
        },
      ],
    },
    {
      apiKey: auth.apiKey,
      headers: auth.headers,
      maxTokens: 80,
      reasoning: "minimal",
      signal,
    },
  );

  state.evaluationUsage = addUsage(state.evaluationUsage, usageTotals(response.usage));
  if (response.stopReason === "error" || response.stopReason === "aborted" || response.errorMessage) return undefined;

  const text = messageText(response).trim();
  const parsed = parseJsonObject(text);
  return sanitizeShortCondition(parsed?.label) ?? sanitizeShortCondition(text);
}

/** Build the autonomous follow-up prompt used when the evaluator says the goal is unmet. */
function continuationPrompt(state: GoalState): string {
  const verdict = state.latestVerdict;
  return [
    "The active /goal condition is not satisfied yet.",
    "",
    `Completion condition: ${state.condition}`,
    verdict?.reasoning ? `Latest evaluator reasoning: ${verdict.reasoning}` : undefined,
    "",
    "Continue autonomously toward satisfying the condition. Inspect, edit, and run commands as needed.",
    "Do not ask the user to say 'keep going'. If you believe the condition is satisfied, provide concise evidence (for example, relevant passing command output).",
  ]
    .filter(Boolean)
    .join("\n");
}

/** Collapse arbitrary goal text into a single display line. */
function oneLine(text: string): string {
  return text.replace(/\s+/g, " ").trim();
}

/** Normalize a generated widget label, keeping it short enough for narrow status lines. */
function sanitizeShortCondition(value: unknown): string | undefined {
  if (typeof value !== "string") return undefined;

  const cleaned = oneLine(value)
    .replace(/^['"`]+|['"`]+$/g, "")
    .replace(/[.!?]$/g, "")
    .trim();
  if (!cleaned) return undefined;

  return truncateToWidth(cleaned, SHORT_CONDITION_MAX_CHARS, "…");
}

/** Safe immediate fallback while the evaluator model is generating a better widget label. */
function fallbackShortCondition(condition: string): string {
  return sanitizeShortCondition(condition) ?? "goal";
}

/** Return the compact condition label shown in the one-line widget. */
function widgetCondition(state: GoalState): string {
  return state.shortCondition ?? fallbackShortCondition(state.condition);
}

/** Format a turn count with correct singular/plural wording. */
function turnLabel(turnCount: number): string {
  return `${turnCount} ${turnCount === 1 ? "turn" : "turns"}`;
}

/** Return live elapsed time for active goals or frozen elapsed time for completed goals. */
function elapsedForGoal(state: GoalState): string {
  const endAt = state.phase === "done" ? state.endedAt ?? state.latestVerdict?.evaluatedAt ?? Date.now() : Date.now();
  return formatDuration(endAt - state.startedAt);
}

/** Pick the theme color that communicates the current goal state. */
function goalColor(state: GoalState, isChecking: boolean): GoalColor {
  if (state.phase === "active" && isChecking) return "warning";
  if (state.phase === "active") return "accent";
  if (state.latestVerdict?.met) return "success";
  return "muted";
}

/** Convert active/checking/completed state into a compact status label. */
function goalLabel(state: GoalState, isChecking: boolean): string {
  if (state.phase === "active" && isChecking) return "checking";
  if (state.phase === "active") return "active";
  if (state.latestVerdict?.met) return "done";
  return "ended";
}

/** Pick the compact glyph shown in the footer and goal widget. */
function goalIcon(state: GoalState, isChecking: boolean): string {
  if (state.phase === "active" && isChecking) return "…";
  if (state.phase === "active") return "🎯";
  if (state.latestVerdict?.met) return "✓";
  return "□";
}

/** Build the derived display data shared by footer, widget, and /goal status. */
function goalDisplay(
  ctx: ExtensionContext | ExtensionCommandContext,
  state: GoalState,
  isChecking: boolean,
): GoalDisplay {
  const spend = totalSpend(ctx, state);
  return {
    icon: goalIcon(state, isChecking),
    label: goalLabel(state, isChecking),
    color: goalColor(state, isChecking),
    turns: turnLabel(state.turnCount),
    spent: compactMoney(spend.cost),
    elapsed: elapsedForGoal(state),
    condition: widgetCondition(state),
  };
}

/** Render the persistent one-line goal widget, safely truncated to terminal width. */
function renderGoalWidgetLine(
  ctx: ExtensionContext | ExtensionCommandContext,
  state: GoalState,
  theme: ExtensionContext["ui"]["theme"],
  isChecking: boolean,
  width: number,
): string {
  const display = goalDisplay(ctx, state, isChecking);
  const title = theme.fg(display.color, `${display.icon} goal`);
  const condition = theme.fg("text", display.condition);
  const separator = theme.fg("dim", " · ");
  const divider = theme.fg("dim", " │ ");
  const fullStats = theme.fg(
    "dim",
    [display.label, display.turns, `${display.spent} spent`, `${display.elapsed} elapsed`].join(" · "),
  );
  const compactStats = theme.fg("dim", [display.label, `${display.elapsed} elapsed`].join(" · "));

  const line = width < 48
    ? `${title}${separator}${condition}`
    : width < 88
      ? `${title}${separator}${compactStats}${divider}${condition}`
      : `${title}${separator}${fullStats}${divider}${condition}`;

  return truncateToWidth(line, width, "…");
}

/** Create the live-updating goal widget component shown above the editor. */
function createGoalWidget(
  ctx: ExtensionContext | ExtensionCommandContext,
  getState: () => GoalState | undefined,
  isChecking: () => boolean,
  tui: TUI,
  theme: ExtensionContext["ui"]["theme"],
): Component & { dispose(): void } {
  const refresh = () => {
    if (getState()?.phase === "active") tui.requestRender();
  };
  const timer = setInterval(refresh, 1000);
  (timer as unknown as { unref?: () => void }).unref?.();

  return {
    render(width: number): string[] {
      const current = getState();
      if (!current || width <= 0) return [];
      return [renderGoalWidgetLine(ctx, current, theme, isChecking(), width)];
    },
    invalidate() {},
    dispose() {
      clearInterval(timer);
    },
  };
}

/** Show a notification with full goal details for bare /goal invocations. */
function showGoalStatus(ctx: ExtensionCommandContext, state: GoalState): void {
  const spend = totalSpend(ctx, state);
  const verdict = state.latestVerdict;
  const display = goalDisplay(ctx, state, false);
  const lines = [
    `Goal: ${state.condition}`,
    `Widget label: ${display.condition}`,
    `Status: ${display.label}`,
    `Turns: ${display.turns}`,
    `Elapsed: ${display.elapsed}`,
    `Spend: ${money(spend.cost)} (${spend.tokens.toLocaleString()} tokens, incl. evaluator)`,
    `Evaluator: ${verdict?.evaluatorModel ?? "not run yet"}`,
    `Latest verdict: ${verdict ? (verdict.met ? "met" : "not met") : "not run yet"}`,
    `Reasoning: ${verdict?.reasoning ?? "No evaluator verdict yet."}`,
  ];

  ctx.ui.notify(lines.join("\n"), "info");
}

/** Register the /goal command and all lifecycle hooks that keep goal state/UI in sync. */
export default function goalExtension(pi: ExtensionAPI) {
  let state: GoalState | undefined;
  let pendingStart: PendingGoalStart | undefined;
  let nextPendingStartId = 0;
  let evaluating = false;
  let evaluationAbort: AbortController | undefined;
  let shortConditionAbort: AbortController | undefined;
  let widgetInstalled = false;

  /** Persist the current goal snapshot as a branch-aware custom session entry. */
  function persist(): void {
    pi.appendEntry<PersistedGoal>(CUSTOM_TYPE, state ? { type: "goal", state } : { type: "dismissed" });
  }

  /** Install, refresh, or clear the persistent goal widget. */
  function applyStatus(ctx: ExtensionContext | ExtensionCommandContext): void {
    if (!ctx.hasUI) return;

    // The widget carries goal status; clear any stale footer status from older versions.
    ctx.ui.setStatus("goal", undefined);

    if (!state) {
      if (widgetInstalled) {
        ctx.ui.setWidget("goal", undefined);
        widgetInstalled = false;
      }
      return;
    }

    if (!widgetInstalled) {
      ctx.ui.setWidget(
        "goal",
        (tui, theme) => createGoalWidget(ctx, () => state, () => evaluating, tui, theme),
        { placement: "aboveEditor" },
      );
      widgetInstalled = true;
    }
  }

  /** Restore the latest goal state visible on the current session branch. */
  function restore(ctx: ExtensionContext): void {
    pendingStart = undefined;
    shortConditionAbort?.abort();
    shortConditionAbort = undefined;
    state = undefined;

    for (const entry of ctx.sessionManager.getBranch() as SessionEntry[]) {
      if (entry.type !== "custom" || entry.customType !== CUSTOM_TYPE) continue;

      const restored = restoreGoalEntry(entry.data);
      if (restored.kind === "goal") state = restored.state;
      if (restored.kind === "dismissed") state = undefined;
    }

    applyStatus(ctx);
    if (state?.phase === "active" && !state.shortCondition) void refreshShortCondition(ctx, state);
  }

  /** Generate and persist a compact condition label without blocking goal startup. */
  async function refreshShortCondition(ctx: ExtensionContext | ExtensionCommandContext, current: GoalState): Promise<void> {
    shortConditionAbort?.abort();
    const abortController = new AbortController();
    shortConditionAbort = abortController;

    try {
      const label = await generateShortCondition(ctx, current, abortController.signal);
      if (!label || abortController.signal.aborted || state !== current) return;

      current.shortCondition = label;
      persist();
      applyStatus(ctx);
    } catch {
      // The fallback label is already short; model-label failures are non-fatal.
    } finally {
      if (shortConditionAbort === abortController) shortConditionAbort = undefined;
    }
  }

  /** Run goal evaluation, persist the verdict, and continue autonomously if unmet. */
  async function evaluateAndMaybeContinue(ctx: ExtensionContext | ExtensionCommandContext): Promise<void> {
    const current = state;
    if (!current || current.phase !== "active" || evaluating) return;

    evaluating = true;
    const abortController = new AbortController();
    evaluationAbort = abortController;
    applyStatus(ctx);

    try {
      const verdict = await evaluateGoal(ctx, current, combinedAbortSignal(ctx.signal, abortController.signal));
      if (state !== current || current.phase !== "active") return;

      current.latestVerdict = verdict;

      if (verdict.met) {
        current.phase = "done";
        current.endedAt = verdict.evaluatedAt;
        current.finalUsage = totalSpend(ctx, current);
        persist();
        applyStatus(ctx);
        if (ctx.hasUI) ctx.ui.notify(`Goal satisfied. Dismiss with /goal end.\n${verdict.reasoning}`, "info");
        return;
      }

      persist();
      applyStatus(ctx);

      if (verdict.error) {
        if (ctx.hasUI) ctx.ui.notify(`Goal evaluator error: ${verdict.reasoning}`, "error");
        return;
      }

      if (ctx.isIdle()) {
        pi.sendUserMessage(continuationPrompt(current));
      } else {
        pi.sendUserMessage(continuationPrompt(current), { deliverAs: "followUp" });
      }
    } catch (error) {
      if (state !== current || current.phase !== "active") return;

      current.latestVerdict = {
        met: false,
        reasoning: error instanceof Error ? error.message : String(error),
        evaluatedAt: Date.now(),
        error: "evaluation-failed",
      };
      persist();
      if (ctx.hasUI) {
        ctx.ui.notify(`Goal evaluation failed: ${error instanceof Error ? error.message : String(error)}`, "error");
      }
    } finally {
      if (evaluationAbort === abortController) evaluationAbort = undefined;
      evaluating = false;
      applyStatus(ctx);
    }
  }

  pi.on("session_start", async (_event, ctx) => {
    restore(ctx);
  });

  pi.on("session_tree", async (_event, ctx) => {
    restore(ctx);
  });

  pi.on("session_shutdown", async (_event, ctx) => {
    pendingStart = undefined;
    shortConditionAbort?.abort();
    shortConditionAbort = undefined;
    evaluationAbort?.abort();
    evaluationAbort = undefined;
    if (!ctx.hasUI) return;
    ctx.ui.setStatus("goal", undefined);
    ctx.ui.setWidget("goal", undefined);
    widgetInstalled = false;
  });

  pi.on("before_agent_start", async (event) => {
    if (state?.phase !== "active") return;
    return {
      systemPrompt: `${event.systemPrompt}\n\nActive /goal completion condition: ${state.condition}\nContinue working autonomously until this condition is demonstrably satisfied.`,
    };
  });

  pi.on("turn_end", async (_event, ctx) => {
    if (state?.phase !== "active") return;
    state.turnCount += 1;
    applyStatus(ctx);
  });

  pi.on("agent_end", async (_event, ctx) => {
    if (state?.phase !== "active") return;
    await evaluateAndMaybeContinue(ctx);
  });

  pi.registerCommand("goal", {
    description: "Set, inspect, or dismiss an autonomous completion goal",
    handler: async (args, ctx) => {
      const text = args.trim();
      const lowered = text.toLowerCase();

      if (!text || STATUS_WORDS.has(lowered)) {
        if (state) {
          showGoalStatus(ctx, state);
          return;
        }
        if (pendingStart) {
          ctx.ui.notify(`Goal pending until the agent is idle: ${pendingStart.condition}`, "info");
          return;
        }
        ctx.ui.notify("No goal.", "info");
        return;
      }

      if (DISMISS_WORDS.has(lowered)) {
        const dismissedState = state;
        const dismissedPendingStart = pendingStart;
        const wasEvaluating = evaluating;
        const shouldInterrupt =
          wasEvaluating ||
          (!!dismissedState && dismissedState.phase === "active" && INTERRUPT_WORDS.has(lowered)) ||
          (!!dismissedPendingStart && INTERRUPT_WORDS.has(lowered));

        if (!dismissedState && !dismissedPendingStart && !wasEvaluating) {
          ctx.ui.notify("No goal to dismiss.", "info");
          return;
        }

        pendingStart = undefined;
        state = undefined;
        shortConditionAbort?.abort();
        shortConditionAbort = undefined;
        evaluationAbort?.abort();
        evaluationAbort = undefined;
        if (dismissedState) persist();
        applyStatus(ctx);

        if (shouldInterrupt && (!ctx.isIdle() || ctx.hasPendingMessages())) {
          ctx.abort();
          await ctx.waitForIdle();
        }

        const cancelledPending = dismissedPendingStart && !dismissedState;
        const message = cancelledPending ? "Pending goal cancelled." : "Goal dismissed.";
        ctx.ui.notify(shouldInterrupt ? `${message} Interrupted active work.` : message, "info");
        return;
      }

      const pending = { id: ++nextPendingStartId, condition: text };
      pendingStart = pending;
      if (!ctx.isIdle()) {
        ctx.ui.notify(`Goal queued until the agent is idle: ${text}`, "info");
      }

      await ctx.waitForIdle();
      if (pendingStart !== pending) return;
      pendingStart = undefined;

      state = {
        phase: "active",
        condition: text,
        shortCondition: fallbackShortCondition(text),
        startedAt: Date.now(),
        startEntryId: ctx.sessionManager.getLeafId(),
        turnCount: 0,
        evaluationUsage: { tokens: 0, cost: 0 },
      };
      persist();
      applyStatus(ctx);
      ctx.ui.notify(`Goal set: ${text}`, "info");

      void refreshShortCondition(ctx, state);
      await evaluateAndMaybeContinue(ctx);
    },
  });
}
