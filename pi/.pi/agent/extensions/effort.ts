import {
  SettingsSelectorComponent,
  type ExtensionAPI,
  type ExtensionCommandContext,
} from "@earendil-works/pi-coding-agent";
import {
  getSupportedThinkingLevels,
  type ModelThinkingLevel,
} from "@earendil-works/pi-ai";
import { SettingsList } from "@earendil-works/pi-tui";

type ThinkingLevel = ModelThinkingLevel;

const THINKING_LEVELS: ThinkingLevel[] = ["off", "minimal", "low", "medium", "high", "xhigh"];
const EFFORT_SEARCH_ALIASES = ["effort", "modeleffort", "reasoningeffort"];
const noop = () => {};

function normalize(value: string): string {
  return value.toLowerCase().replace(/[^a-z0-9]+/g, "");
}

function isEffortSearch(query: string): boolean {
  const normalized = normalize(query);
  if (normalized.length < 2) return false;

  return EFFORT_SEARCH_ALIASES.some((alias) =>
    normalized.length < 3
      ? alias.startsWith(normalized)
      : alias.includes(normalized) || normalized.includes(alias),
  );
}

function availableThinkingLevels(ctx: ExtensionCommandContext): ThinkingLevel[] {
  if (!ctx.model) return [...THINKING_LEVELS];
  const levels = getSupportedThinkingLevels(ctx.model);
  return levels.length > 0 ? levels : ["off"];
}

function settingsConfig(pi: ExtensionAPI, ctx: ExtensionCommandContext) {
  return {
    autoCompact: true,
    showImages: true,
    imageWidthCells: 60,
    autoResizeImages: true,
    blockImages: false,
    enableSkillCommands: true,
    steeringMode: "one-at-a-time",
    followUpMode: "one-at-a-time",
    transport: "auto",
    httpIdleTimeoutMs: 300000,
    thinkingLevel: pi.getThinkingLevel(),
    availableThinkingLevels: availableThinkingLevels(ctx),
    currentTheme: "dark",
    availableThemes: ["dark", "light"],
    hideThinkingBlock: false,
    collapseChangelog: false,
    enableInstallTelemetry: true,
    doubleEscapeAction: "tree",
    treeFilterMode: "default",
    showHardwareCursor: false,
    editorPaddingX: 0,
    autocompleteMaxVisible: 5,
    quietStartup: false,
    clearOnShrink: false,
    showTerminalProgress: false,
    warnings: { anthropicExtraUsage: true },
  } as ConstructorParameters<typeof SettingsSelectorComponent>[0];
}

function settingsCallbacks(
  onThinkingLevelChange: (level: ThinkingLevel) => void,
  onCancel: () => void,
) {
  return new Proxy(
    { onThinkingLevelChange, onCancel },
    { get: (target, prop) => Reflect.get(target, prop) ?? noop },
  ) as ConstructorParameters<typeof SettingsSelectorComponent>[1];
}

async function openThinkingLevelSubmenu(
  pi: ExtensionAPI,
  ctx: ExtensionCommandContext,
) {
  await ctx.ui.custom<void>((_tui, _theme, _keybindings, done) => {
    const selector = new SettingsSelectorComponent(
      settingsConfig(pi, ctx),
      settingsCallbacks(
        (level) => {
          pi.setThinkingLevel(level);
          done();
        },
        done,
      ),
    );

    // SettingsList does not expose a public API to open one submenu directly.
    // Reuse Pi's component, then jump to and activate its private thinking item.
    const list = selector.getSettingsList() as any;

    const component = {
      render: (width: number) => selector.render(width),
      invalidate: () => selector.invalidate(),
      handleInput: (data: string) => list.handleInput(data),
    };

    const thinkingIndex = list.items?.findIndex((item) => item.id === "thinking");
    if (thinkingIndex === undefined || thinkingIndex < 0) {
      done();
      return component;
    }

    list.filteredItems = list.items;
    list.selectedIndex = thinkingIndex;
    list.activateItem?.();
    if (list.submenuComponent?.selectList) {
      list.submenuComponent.selectList.onCancel = done;
    }

    return component;
  });
}

function installSettingsEffortAlias(): () => void {
  const proto = SettingsList.prototype as any;

  if (proto.__piEffortAliasOriginalApplyFilter || !proto.applyFilter) {
    return noop;
  }

  const originalApplyFilter = proto.applyFilter;

  proto.applyFilter = function applyFilterWithEffortAlias(this: any, query: string) {
    originalApplyFilter.call(this, query);
    if (!isEffortSearch(query)) return;

    const thinkingItem = this.items?.find(
      (item) => item.id === "thinking" || item.label === "Thinking level",
    );
    if (!thinkingItem || this.filteredItems?.includes(thinkingItem)) return;

    this.filteredItems = [thinkingItem, ...(this.filteredItems ?? [])];
    this.selectedIndex = 0;
  };

  proto.__piEffortAliasOriginalApplyFilter = originalApplyFilter;

  return () => {
    if (proto.__piEffortAliasOriginalApplyFilter === originalApplyFilter) {
      proto.applyFilter = originalApplyFilter;
      delete proto.__piEffortAliasOriginalApplyFilter;
    }
  };
}

export default function (pi: ExtensionAPI) {
  const restoreSettingsAlias = installSettingsEffortAlias();
  pi.on("session_shutdown", restoreSettingsAlias);

  pi.registerCommand("effort", {
    description: "Set model effort (thinking level)",
    handler: async (_args, ctx) => {
      if (!ctx.hasUI) {
        ctx.ui.notify(`Current effort: ${pi.getThinkingLevel()}.`, "info");
        return;
      }

      await openThinkingLevelSubmenu(pi, ctx);
    },
  });
}
