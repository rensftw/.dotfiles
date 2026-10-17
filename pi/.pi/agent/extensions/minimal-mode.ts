import type {
  ExtensionAPI,
  ToolDefinition,
} from "@earendil-works/pi-coding-agent";
import {
  createBashToolDefinition,
  createEditToolDefinition,
  createFindToolDefinition,
  createGrepToolDefinition,
  createLsToolDefinition,
  createReadToolDefinition,
  createWriteToolDefinition,
} from "@earendil-works/pi-coding-agent";
import { type Component, Text } from "@earendil-works/pi-tui";
import { homedir } from "node:os";
import { sep } from "node:path";
import type { TSchema } from "typebox";

/**
 * Keep built-in tool behavior, prompt metadata, and expanded renderers while
 * making the collapsed view minimal. Ctrl+O still reveals Pi's full native
 * rendering, including syntax highlighting, diffs, truncation notices, and
 * streaming/error details.
 */

interface MinimalToolOptions<
  TParams extends TSchema,
  TDetails,
  TState,
> {
  renderCollapsedCall?: NonNullable<
    ToolDefinition<TParams, TDetails, TState>["renderCall"]
  >;
  renderCollapsedResult?: NonNullable<
    ToolDefinition<TParams, TDetails, TState>["renderResult"]
  >;
}

function updateText(lastComponent: Component | undefined, value: string): Text {
  const component = lastComponent instanceof Text
    ? lastComponent
    : new Text("", 0, 0);
  component.setText(value);
  return component;
}

function shortenPath(path: string): string {
  const home = homedir();
  if (path === home) return "~";
  if (path.startsWith(`${home}${sep}`)) return `~${path.slice(home.length)}`;
  return path;
}

function countResultLines(
  content: ReadonlyArray<{ type: string; text?: string }>,
): number {
  const text = content.find((item) => item.type === "text")?.text?.trim();
  if (!text) return 0;

  const output = text.split("\n\n[")[0]?.trim() ?? "";
  if (
    !output ||
    /^No (?:files found|matches found)/i.test(output) ||
    output === "(empty directory)"
  ) {
    return 0;
  }

  return output.split("\n").filter(Boolean).length;
}

function registerMinimalTool<
  TParams extends TSchema,
  TDetails,
  TState,
>(
  pi: ExtensionAPI,
  createDefinition: (
    cwd: string,
  ) => ToolDefinition<TParams, TDetails, TState>,
  options: MinimalToolOptions<TParams, TDetails, TState> = {},
): void {
  const definitions = new Map<
    string,
    ToolDefinition<TParams, TDetails, TState>
  >();

  const getDefinition = (cwd: string) => {
    let definition = definitions.get(cwd);
    if (!definition) {
      definition = createDefinition(cwd);
      definitions.set(cwd, definition);
    }
    return definition;
  };

  const initial = getDefinition(process.cwd());

  pi.registerTool<TParams, TDetails, TState>({
    ...initial,

    async execute(toolCallId, params, signal, onUpdate, ctx) {
      return getDefinition(ctx.cwd).execute(
        toolCallId,
        params,
        signal,
        onUpdate,
        ctx,
      );
    },

    renderCall(args, theme, context) {
      if (!context.expanded && options.renderCollapsedCall) {
        return options.renderCollapsedCall(args, theme, context);
      }

      const renderer = getDefinition(context.cwd).renderCall;
      return renderer
        ? renderer(args, theme, context)
        : updateText(
            context.lastComponent,
            theme.fg("toolTitle", theme.bold(initial.name)),
          );
    },

    renderResult(result, renderOptions, theme, context) {
      const renderer = getDefinition(context.cwd).renderResult;

      // Errors should remain visible even in minimal mode. Expanded mode always
      // delegates to Pi's current renderer instead of maintaining a local copy.
      if (renderOptions.expanded || context.isError) {
        return renderer
          ? renderer(result, renderOptions, theme, context)
          : updateText(
              context.lastComponent,
              result.content
                .filter((item) => item.type === "text")
                .map((item) => item.text)
                .join("\n"),
            );
      }

      if (!renderOptions.isPartial && options.renderCollapsedResult) {
        return options.renderCollapsedResult(
          result,
          renderOptions,
          theme,
          context,
        );
      }

      return updateText(context.lastComponent, "");
    },
  });
}

export default function minimalMode(pi: ExtensionAPI): void {
  registerMinimalTool(pi, createReadToolDefinition);
  registerMinimalTool(pi, createBashToolDefinition);

  registerMinimalTool(pi, createEditToolDefinition, {
    renderCollapsedCall(args, theme, context) {
      const path = shortenPath(args.path || "");
      return updateText(
        context.lastComponent,
        `${theme.fg("toolTitle", theme.bold("edit"))} ${theme.fg("accent", path || "...")}`,
      );
    },
  });

  registerMinimalTool(pi, createWriteToolDefinition, {
    renderCollapsedCall(args, theme, context) {
      const path = shortenPath(args.path || "");
      const lineCount = args.content ? args.content.split("\n").length : 0;
      const lineInfo = lineCount > 0
        ? theme.fg("muted", ` (${lineCount} lines)`)
        : "";
      return updateText(
        context.lastComponent,
        `${theme.fg("toolTitle", theme.bold("write"))} ${theme.fg("accent", path || "...")}${lineInfo}`,
      );
    },
  });

  registerMinimalTool(pi, createFindToolDefinition, {
    renderCollapsedResult(result, _options, theme, context) {
      const count = countResultLines(result.content);
      return updateText(
        context.lastComponent,
        count > 0 ? theme.fg("muted", ` → ${count} files`) : "",
      );
    },
  });

  registerMinimalTool(pi, createGrepToolDefinition, {
    renderCollapsedResult(result, _options, theme, context) {
      const count = countResultLines(result.content);
      return updateText(
        context.lastComponent,
        count > 0 ? theme.fg("muted", ` → ${count} matches`) : "",
      );
    },
  });

  registerMinimalTool(pi, createLsToolDefinition, {
    renderCollapsedResult(result, _options, theme, context) {
      const count = countResultLines(result.content);
      return updateText(
        context.lastComponent,
        count > 0 ? theme.fg("muted", ` → ${count} entries`) : "",
      );
    },
  });
}
