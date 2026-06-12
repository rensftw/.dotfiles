import type {
  ExtensionAPI,
  ExtensionCommandContext,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { completeSimple, type Api, type Model, type Usage } from "@earendil-works/pi-ai";
import { truncateToWidth, type AutocompleteItem, type Component, type TUI } from "@earendil-works/pi-tui";

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
const DEFAULT_MAX_TURNS = 50;
const DEFAULT_COST_BUDGET = 15;
const GOAL_USAGE =
  "Usage: /goal [--turns N] [--budget DOLLARS|--cost DOLLARS] <completion condition>";
const TURN_VALUE_COMPLETIONS = [String(DEFAULT_MAX_TURNS), "25", "100"];
const COST_VALUE_COMPLETIONS = [String(DEFAULT_COST_BUDGET), "5", "30"];

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

interface GoalLimits {
  maxTurns: number;
  costBudget: number;
}

interface GoalState extends GoalLimits {
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

interface PendingGoalStart extends GoalLimits {
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

interface GoalLimitHit {
  error: "turn-limit-reached" | "cost-budget-reached" | "goal-limit-reached";
  summary: string;
}

interface ParsedGoalArgs {
  condition: string;
  limits: GoalLimits;
  providedLimits: Partial<GoalLimits>;
  hasLimitOptions: boolean;
  error?: string;
}

type EmbeddedGoalInvocation =
  | { kind: "start"; condition: string; agentText: string; limits: GoalLimits }
  | { kind: "help" }
  | { kind: "status" }
  | { kind: "dismiss"; word: string }
  | { kind: "error"; error: string };

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

/** Return a fresh copy of the default autonomous-loop limits. */
function defaultGoalLimits(): GoalLimits {
  return { maxTurns: DEFAULT_MAX_TURNS, costBudget: DEFAULT_COST_BUDGET };
}

/** Normalize a persisted or user-provided turn ceiling into a positive integer. */
function normalizeMaxTurns(value: unknown): number {
  if (typeof value !== "number" || !Number.isFinite(value)) return DEFAULT_MAX_TURNS;
  const turns = Math.floor(value);
  return turns > 0 ? turns : DEFAULT_MAX_TURNS;
}

/** Normalize a persisted or user-provided dollar budget into a positive finite value. */
function normalizeCostBudget(value: unknown): number {
  return typeof value === "number" && Number.isFinite(value) && value > 0 ? value : DEFAULT_COST_BUDGET;
}

/** Normalize a pair of goal limits, applying sensible defaults to missing legacy state. */
function normalizeGoalLimits(value: { maxTurns?: unknown; costBudget?: unknown }): GoalLimits {
  return {
    maxTurns: normalizeMaxTurns(value.maxTurns),
    costBudget: normalizeCostBudget(value.costBudget),
  };
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

  const rawStartEntryId = value.startEntryId;
  const startEntryId: string | null = typeof rawStartEntryId === "string" ? rawStartEntryId : null;
  const endedAt = typeof value.endedAt === "number"
    ? value.endedAt
    : typeof value.completedAt === "number"
      ? value.completedAt
      : undefined;

  const shortCondition = sanitizeShortCondition(value.shortCondition);
  const limits = normalizeGoalLimits({
    maxTurns: value.maxTurns,
    costBudget: value.costBudget ?? value.budget ?? value.maxCost,
  });

  return {
    phase,
    condition: value.condition,
    startedAt: value.startedAt,
    startEntryId,
    turnCount: typeof value.turnCount === "number" ? value.turnCount : 0,
    evaluationUsage: normalizeUsage(value.evaluationUsage ?? value.evaluatorUsage),
    ...limits,
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
  if (state.startEntryId === null) return branch.filter(isMessageEntry);

  const startIndex = branch.findIndex((entry) => entry.id === state.startEntryId);
  const afterStart = startIndex >= 0 ? branch.slice(startIndex + 1) : [];

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

/** Return the autonomous-loop ceiling(s) reached by the current goal, if any. */
function goalLimitHit(ctx: ExtensionContext | ExtensionCommandContext, state: GoalState): GoalLimitHit | undefined {
  const spend = totalSpend(ctx, state);
  const hits: string[] = [];
  let error: GoalLimitHit["error"] | undefined;

  if (state.turnCount >= state.maxTurns) {
    hits.push(`turn limit ${state.turnCount}/${state.maxTurns}`);
    error = "turn-limit-reached";
  }

  if (spend.cost >= state.costBudget) {
    hits.push(`cost budget ${money(spend.cost)}/${money(state.costBudget)}`);
    error = error ? "goal-limit-reached" : "cost-budget-reached";
  }

  return error ? { error, summary: hits.join(" and ") } : undefined;
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

/** Tokenize command arguments, supporting simple single/double-quoted values. */
function tokenizeArgs(input: string): string[] {
  const tokens: string[] = [];
  let current = "";
  let quote: "'" | '"' | undefined;
  let escaped = false;

  for (const char of input) {
    if (escaped) {
      current += char;
      escaped = false;
      continue;
    }

    if (quote) {
      if (char === "\\") {
        escaped = true;
      } else if (char === quote) {
        quote = undefined;
      } else {
        current += char;
      }
      continue;
    }

    if (char === "'" || char === '"') {
      quote = char;
    } else if (/\s/.test(char)) {
      if (current) {
        tokens.push(current);
        current = "";
      }
    } else {
      current += char;
    }
  }

  if (escaped) current += "\\";
  if (current) tokens.push(current);
  return tokens;
}

/** Parse a positive integer turn limit from /goal options. */
function parseTurnLimit(value: string): number | undefined {
  const turns = Number(value);
  return Number.isInteger(turns) && turns > 0 ? turns : undefined;
}

/** Parse a positive dollar budget from /goal options. */
function parseCostBudget(value: string): number | undefined {
  const amount = Number(value.trim().replace(/^\$/, ""));
  return Number.isFinite(amount) && amount > 0 ? amount : undefined;
}

/** Parse leading /goal limit options, leaving the rest as the completion condition. */
function parseGoalArgs(text: string): ParsedGoalArgs {
  const tokens = tokenizeArgs(text);
  const limits = defaultGoalLimits();
  const providedLimits: Partial<GoalLimits> = {};
  let hasLimitOptions = false;
  let index = 0;

  const readOptionValue = (inlineValue?: string): string | undefined => {
    if (inlineValue !== undefined) return inlineValue;
    const next = tokens[index + 1];
    if (!next || next.startsWith("--")) return undefined;
    index += 1;
    return next;
  };
  const fail = (error: string): ParsedGoalArgs => ({
    condition: "",
    limits,
    providedLimits,
    hasLimitOptions,
    error,
  });

  while (index < tokens.length) {
    const token = tokens[index];
    if (token === "--") {
      index += 1;
      break;
    }
    if (!token.startsWith("--")) break;

    const equals = token.indexOf("=");
    const name = equals >= 0 ? token.slice(0, equals) : token;
    const inlineValue = equals >= 0 ? token.slice(equals + 1) : undefined;

    if (name === "--turns" || name === "--max-turns" || name === "--maxTurns") {
      const value = readOptionValue(inlineValue);
      const turns = value ? parseTurnLimit(value) : undefined;
      if (!turns) return fail(`${name} requires a positive whole number. ${GOAL_USAGE}`);
      limits.maxTurns = turns;
      providedLimits.maxTurns = turns;
      hasLimitOptions = true;
      index += 1;
      continue;
    }

    if (
      name === "--budget" ||
      name === "--cost" ||
      name === "--budget/cost" ||
      name === "--max-cost" ||
      name === "--maxCost"
    ) {
      const value = readOptionValue(inlineValue);
      const budget = value ? parseCostBudget(value) : undefined;
      if (!budget) return fail(`${name} requires a positive dollar amount. ${GOAL_USAGE}`);
      limits.costBudget = budget;
      providedLimits.costBudget = budget;
      hasLimitOptions = true;
      index += 1;
      continue;
    }

    return fail(`Unknown /goal option ${name}. ${GOAL_USAGE}`);
  }

  return {
    condition: tokens.slice(index).join(" ").trim(),
    limits,
    providedLimits,
    hasLimitOptions,
  };
}

/** Parse a /goal directive when it appears at the start of any line in a larger prompt. */
function parseEmbeddedGoalInvocation(text: string): EmbeddedGoalInvocation | undefined {
  const lines = text.split(/\r?\n/);

  for (let index = 0; index < lines.length; index += 1) {
    const match = lines[index].match(/^[ \t]*\/goal(?:[ \t]+(.*)|[ \t]*)$/);
    if (!match) continue;

    const argsText = (match[1] ?? "").trim();
    const lowered = argsText.toLowerCase();
    const surroundingText = [...lines.slice(0, index), ...lines.slice(index + 1)].join("\n").trim();

    // Preserve command-style behavior for indented/buried control invocations that have no prompt body.
    if (!surroundingText) {
      if (lowered === "help" || lowered === "--help") return { kind: "help" };
      if (!argsText || STATUS_WORDS.has(lowered)) return { kind: "status" };
      if (DISMISS_WORDS.has(lowered)) return { kind: "dismiss", word: lowered };
    }

    const parsed = parseGoalArgs(argsText);
    if (parsed.error) return { kind: "error", error: parsed.error };

    const promptLines = [
      ...lines.slice(0, index),
      ...(parsed.condition ? [parsed.condition] : []),
      ...lines.slice(index + 1),
    ];
    const agentText = promptLines.join("\n").trim();
    const condition = agentText || parsed.condition;

    if (!condition) return { kind: "error", error: `No goal condition provided. ${GOAL_USAGE}` };

    return {
      kind: "start",
      condition,
      agentText: agentText || condition,
      limits: parsed.limits,
    };
  }

  return undefined;
}

type GoalOptionKind = "turns" | "budget";

/** Return the canonical goal option kind for an option token. */
function goalOptionKind(token: string): GoalOptionKind | undefined {
  const name = token.split("=", 1)[0];
  if (name === "--turns" || name === "--max-turns" || name === "--maxTurns") return "turns";
  if (
    name === "--budget" ||
    name === "--cost" ||
    name === "--budget/cost" ||
    name === "--max-cost" ||
    name === "--maxCost"
  ) {
    return "budget";
  }
  return undefined;
}

/** Split the full command-argument prefix into text before and inside the token being completed. */
function splitArgumentCompletion(argumentPrefix: string): { beforeToken: string; currentToken: string } {
  const currentToken = argumentPrefix.match(/\S*$/)?.[0] ?? "";
  return {
    beforeToken: argumentPrefix.slice(0, argumentPrefix.length - currentToken.length),
    currentToken,
  };
}

/** Return tokens already completed before the token currently being edited. */
function completedArgumentTokens(argumentPrefix: string, currentToken: string): string[] {
  const tokens = tokenizeArgs(argumentPrefix);
  return currentToken ? tokens.slice(0, -1) : tokens;
}

/** Autocomplete numeric values for an option that is waiting for its argument. */
function goalValueCompletions(
  kind: GoalOptionKind,
  beforeToken: string,
  currentToken: string,
  optionPrefix = "",
): AutocompleteItem[] | null {
  const values = kind === "turns" ? TURN_VALUE_COMPLETIONS : COST_VALUE_COMPLETIONS;
  const normalizedToken = kind === "budget" ? currentToken.replace(/^\$/, "") : currentToken;
  const items = values
    .filter((value) => value.startsWith(normalizedToken))
    .map((value) => ({
      value: `${beforeToken}${optionPrefix}${value} `,
      label: value,
      description: kind === "turns"
        ? `${value} autonomous turns${value === String(DEFAULT_MAX_TURNS) ? " (default)" : ""}`
        : `${money(Number(value))} spend budget${value === String(DEFAULT_COST_BUDGET) ? " (default)" : ""}`,
    }));

  return items.length > 0 ? items : null;
}

/** Suggest /goal options and control words as the user types command arguments. */
function goalArgumentCompletions(argumentPrefix: string): AutocompleteItem[] | null {
  const { beforeToken, currentToken } = splitArgumentCompletion(argumentPrefix);
  const inlineOption = currentToken.match(/^(--(?:turns|max-turns|maxTurns|budget|cost|budget\/cost|max-cost|maxCost)=)(.*)$/);
  if (inlineOption) {
    const kind = goalOptionKind(inlineOption[1].slice(0, -1));
    return kind ? goalValueCompletions(kind, beforeToken, inlineOption[2], inlineOption[1]) : null;
  }

  const completedTokens = completedArgumentTokens(argumentPrefix, currentToken);
  const previousToken = completedTokens.at(-1) ?? "";
  const previousOptionKind = goalOptionKind(previousToken);
  if (previousOptionKind && !previousToken.includes("=") && !currentToken.startsWith("--")) {
    return goalValueCompletions(previousOptionKind, beforeToken, currentToken);
  }

  const usedOptions = new Set(completedTokens.map(goalOptionKind).filter((kind): kind is GoalOptionKind => !!kind));
  const items: AutocompleteItem[] = [];

  if (currentToken === "" || currentToken.startsWith("--")) {
    for (const option of [
      {
        value: "--turns ",
        label: "--turns",
        kind: "turns" as const,
        description: `Max autonomous turns (default ${DEFAULT_MAX_TURNS})`,
      },
      {
        value: "--budget ",
        label: "--budget",
        kind: "budget" as const,
        description: `Max total spend in dollars (default ${money(DEFAULT_COST_BUDGET)})`,
      },
      {
        value: "--cost ",
        label: "--cost",
        kind: "budget" as const,
        description: "Alias for --budget",
      },
    ]) {
      if (usedOptions.has(option.kind) || !option.label.startsWith(currentToken)) continue;
      items.push({ value: `${beforeToken}${option.value}`, label: option.label, description: option.description });
    }
  }

  if (completedTokens.length === 0 && !currentToken.startsWith("--")) {
    for (const item of [
      { value: "status", label: "status", description: "Show active goal status" },
      { value: "stop", label: "stop", description: "Dismiss the active or pending goal" },
      { value: "help", label: "help", description: "Show /goal usage and defaults" },
    ]) {
      if (currentToken && !item.label.startsWith(currentToken)) continue;
      items.push({ ...item, value: `${beforeToken}${item.value}` });
    }
  }

  return items.length > 0 ? items : null;
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
  if (auth.ok === false) {
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
      signal,
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

/** Format turn progress against the configured autonomous-loop ceiling. */
function turnLabel(state: GoalState): string {
  return `${state.turnCount}/${state.maxTurns} turns`;
}

/** Format spend progress against the configured dollar budget. */
function spendLabel(spend: GoalUsage, state: GoalState): string {
  return `${compactMoney(spend.cost)}/${compactMoney(state.costBudget)}`;
}

/** Format the configured loop ceilings for notifications. */
function limitsSummary(limits: GoalLimits): string {
  return `${limits.maxTurns} turns, ${money(limits.costBudget)} budget`;
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
    turns: turnLabel(state),
    spent: spendLabel(spend, state),
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
function showGoalStatus(ctx: ExtensionContext | ExtensionCommandContext, state: GoalState): void {
  const spend = totalSpend(ctx, state);
  const verdict = state.latestVerdict;
  const display = goalDisplay(ctx, state, false);
  const lines = [
    `Goal: ${state.condition}`,
    `Widget label: ${display.condition}`,
    `Status: ${display.label}`,
    `Turns: ${display.turns}`,
    `Elapsed: ${display.elapsed}`,
    `Spend: ${money(spend.cost)} / ${money(state.costBudget)} budget (${spend.tokens.toLocaleString()} tokens, incl. evaluator)`,
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

  /** Activate a new goal from either /goal command arguments or an embedded prompt directive. */
  function activateGoal(pending: PendingGoalStart, ctx: ExtensionContext | ExtensionCommandContext): GoalState {
    pendingStart = undefined;
    shortConditionAbort?.abort();
    shortConditionAbort = undefined;
    evaluationAbort?.abort();
    evaluationAbort = undefined;
    evaluating = false;

    state = {
      phase: "active",
      condition: pending.condition,
      shortCondition: fallbackShortCondition(pending.condition),
      startedAt: Date.now(),
      startEntryId: ctx.sessionManager.getLeafId(),
      turnCount: 0,
      evaluationUsage: { tokens: 0, cost: 0 },
      maxTurns: pending.maxTurns,
      costBudget: pending.costBudget,
    };
    persist();
    applyStatus(ctx);
    if (ctx.hasUI) ctx.ui.notify(`Goal set: ${pending.condition}\nLimits: ${limitsSummary(state)}`, "info");

    void refreshShortCondition(ctx, state);
    return state;
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
      // Do not combine in the just-finished turn's signal: after an interrupt it may
      // already be aborted, which would make every post-interrupt evaluation fail.
      const verdict = await evaluateGoal(ctx, current, abortController.signal);
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

      const limit = goalLimitHit(ctx, current);
      if (limit) {
        current.phase = "done";
        current.endedAt = verdict.evaluatedAt;
        current.latestVerdict = {
          ...verdict,
          reasoning: `${verdict.reasoning}\n\nStopped because the /goal ${limit.summary} was reached.`,
          error: limit.error,
        };
        current.finalUsage = totalSpend(ctx, current);
        persist();
        applyStatus(ctx);
        if (ctx.hasUI) ctx.ui.notify(`Goal stopped: ${limit.summary} reached.\n${verdict.reasoning}`, "warning");
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
      if (evaluationAbort === abortController) {
        evaluationAbort = undefined;
        evaluating = false;
        applyStatus(ctx);
      }
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
      systemPrompt: [
        event.systemPrompt,
        "",
        `Active /goal completion condition: ${state.condition}`,
        `Active /goal limits: ${state.maxTurns} turns, ${money(state.costBudget)} total spend.`,
        "Continue working autonomously until this condition is demonstrably satisfied.",
      ].join("\n"),
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

  pi.on("input", async (event, ctx) => {
    if (event.source === "extension") return { action: "continue" };

    const embeddedGoal = parseEmbeddedGoalInvocation(event.text);
    if (!embeddedGoal) return { action: "continue" };

    if (embeddedGoal.kind === "help") {
      ctx.ui.notify(`${GOAL_USAGE}\nDefaults: ${limitsSummary(defaultGoalLimits())}`, "info");
      return { action: "handled" };
    }

    if (embeddedGoal.kind === "status") {
      if (state) {
        showGoalStatus(ctx, state);
      } else if (pendingStart) {
        ctx.ui.notify(
          `Goal pending until the agent is idle: ${pendingStart.condition}\nLimits: ${limitsSummary(pendingStart)}`,
          "info",
        );
      } else {
        ctx.ui.notify("No goal.", "info");
      }
      return { action: "handled" };
    }

    if (embeddedGoal.kind === "dismiss") {
      const dismissedState = state;
      const dismissedPendingStart = pendingStart;
      const wasEvaluating = evaluating;
      const shouldInterrupt =
        wasEvaluating ||
        (!!dismissedState && dismissedState.phase === "active" && INTERRUPT_WORDS.has(embeddedGoal.word)) ||
        (!!dismissedPendingStart && INTERRUPT_WORDS.has(embeddedGoal.word));

      if (!dismissedState && !dismissedPendingStart && !wasEvaluating) {
        ctx.ui.notify("No goal to dismiss.", "info");
        return { action: "handled" };
      }

      pendingStart = undefined;
      state = undefined;
      shortConditionAbort?.abort();
      shortConditionAbort = undefined;
      evaluationAbort?.abort();
      evaluationAbort = undefined;
      evaluating = false;
      if (dismissedState) persist();
      applyStatus(ctx);

      if (shouldInterrupt && (!ctx.isIdle() || ctx.hasPendingMessages())) ctx.abort();

      const cancelledPending = dismissedPendingStart && !dismissedState;
      const message = cancelledPending ? "Pending goal cancelled." : "Goal dismissed.";
      ctx.ui.notify(shouldInterrupt ? `${message} Interrupted active work.` : message, "info");
      return { action: "handled" };
    }

    if (embeddedGoal.kind === "error") {
      ctx.ui.notify(embeddedGoal.error, "error");
      return { action: "handled" };
    }

    const pending = { id: ++nextPendingStartId, condition: embeddedGoal.condition, ...embeddedGoal.limits };
    activateGoal(pending, ctx);

    return event.images
      ? { action: "transform", text: embeddedGoal.agentText, images: event.images }
      : { action: "transform", text: embeddedGoal.agentText };
  });

  pi.registerCommand("goal", {
    description: "Set, inspect, or dismiss an autonomous completion goal (--turns, --budget/--cost)",
    getArgumentCompletions: goalArgumentCompletions,
    handler: async (args, ctx) => {
      const text = args.trim();
      const lowered = text.toLowerCase();

      if (lowered === "help" || lowered === "--help") {
        ctx.ui.notify(`${GOAL_USAGE}\nDefaults: ${limitsSummary(defaultGoalLimits())}`, "info");
        return;
      }

      if (!text || STATUS_WORDS.has(lowered)) {
        if (state) {
          showGoalStatus(ctx, state);
          return;
        }
        if (pendingStart) {
          ctx.ui.notify(
            `Goal pending until the agent is idle: ${pendingStart.condition}\nLimits: ${limitsSummary(pendingStart)}`,
            "info",
          );
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
        evaluating = false;
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

      const parsed = parseGoalArgs(text);
      if (parsed.error) {
        ctx.ui.notify(parsed.error, "error");
        return;
      }

      if (!parsed.condition) {
        if (!parsed.hasLimitOptions) {
          ctx.ui.notify(GOAL_USAGE, "info");
          return;
        }

        if (state?.phase === "active") {
          state.maxTurns = parsed.providedLimits.maxTurns ?? state.maxTurns;
          state.costBudget = parsed.providedLimits.costBudget ?? state.costBudget;

          const limit = goalLimitHit(ctx, state);
          if (limit) {
            const endedAt = Date.now();
            state.phase = "done";
            state.endedAt = endedAt;
            state.latestVerdict = {
              met: false,
              reasoning: `Stopped because the /goal ${limit.summary} was reached after updating limits.`,
              evaluatedAt: endedAt,
              error: limit.error,
            };
            state.finalUsage = totalSpend(ctx, state);
            persist();
            applyStatus(ctx);
            ctx.ui.notify(`Goal stopped: ${limit.summary} reached after updating limits.`, "warning");
            return;
          }

          persist();
          applyStatus(ctx);
          ctx.ui.notify(`Goal limits updated: ${limitsSummary(state)}`, "info");
          return;
        }

        if (pendingStart) {
          pendingStart.maxTurns = parsed.providedLimits.maxTurns ?? pendingStart.maxTurns;
          pendingStart.costBudget = parsed.providedLimits.costBudget ?? pendingStart.costBudget;
          ctx.ui.notify(`Pending goal limits updated: ${limitsSummary(pendingStart)}`, "info");
          return;
        }

        ctx.ui.notify(`No goal condition provided. ${GOAL_USAGE}`, "error");
        return;
      }

      const pending = { id: ++nextPendingStartId, condition: parsed.condition, ...parsed.limits };
      pendingStart = pending;
      if (!ctx.isIdle()) {
        ctx.ui.notify(
          `Goal queued until the agent is idle: ${parsed.condition}\nLimits: ${limitsSummary(pending)}`,
          "info",
        );
      }

      await ctx.waitForIdle();
      if (pendingStart !== pending) return;
      pendingStart = undefined;

      activateGoal(pending, ctx);
      await evaluateAndMaybeContinue(ctx);
    },
  });
}
