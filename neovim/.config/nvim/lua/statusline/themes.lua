--[[
statusline.themes

Palette definitions consumed by statusline.highlights. Each theme
provides two tables:
  colors   — segment colours (text, git_branch_background, diagnostics, …)
  vi_mode  — mode-name → colour map (15 keys matching providers.mode_names)

The active table at the bottom decides which palette the highlights
module reads. Swap its value to re-theme the bar.
]]

local M = {}

-- tokyonight ---------------------------------------------------------
local ok, tokyonight = pcall(require, 'tokyonight.colors')
if ok then
    local p = tokyonight.setup({ style = 'night' })

    M.tokyonight_colors = {
        background            = p.bg_dark,
        text                  = p.fg,
        inverted_text         = p.bg_dark,
        git_branch_background = p.fg_gutter,
        git_diff_added        = p.teal,
        git_diff_removed      = p.red,
        git_diff_changed      = p.fg,
        diagnostic_errors     = p.red,
        diagnostic_warnings   = p.yellow,
        diagnostic_info       = p.cyan,
        diagnostic_hints      = p.cyan,
        obsession             = p.magenta,
        harpoon               = p.green1,
        lazy                  = p.orange,
        winbar_active         = '#0db9d7',
        winbar_inactive       = '#a9b1d6',
    }

    -- Keys below become suffixes for highlight groups generated in
    -- statusline.highlights: StlMode<KEY>, StlModeSep<KEY>, StlModeBlock<KEY>,
    -- StlModePos<KEY>, StlChevron<KEY>. NORMAL -> StlModeNORMAL, etc.
    -- If you add a key here, also add it to providers.mode_names so vim
    -- modes can resolve to it.
    M.tokyonight_vi_mode_colors = {
        NORMAL        = p.teal,
        OP            = p.blue5,
        INSERT        = p.yellow,
        VISUAL        = p.magenta2,
        LINES         = p.magenta2,
        BLOCK         = p.magenta2,
        REPLACE       = p.red,
        ['V-REPLACE'] = p.red,
        ENTER         = p.cyan,
        MORE          = p.cyan,
        SELECT        = p.orange,
        COMMAND       = p.blue,
        SHELL         = p.teal,
        TERM          = p.teal,
        NONE          = p.teal,
    }
else
    M.tokyonight_colors, M.tokyonight_vi_mode_colors = {}, {}
end

-- catppuccin (available but not wired as active) ---------------------
local ok_cat, catppuccin = pcall(require, 'catppuccin.palettes')
if ok_cat then
    local p = catppuccin.get_palette()

    M.catpuccin_colors = {
        background            = p.base,
        text                  = p.text,
        inverted_text         = p.base,
        git_branch_background = p.surface1,
        git_diff_added        = p.green,
        git_diff_removed      = p.red,
        git_diff_changed      = p.subtext1,
        diagnostic_errors     = p.red,
        diagnostic_warnings   = p.peach,
        diagnostic_info       = p.sky,
        diagnostic_hints      = p.sapphire,
        obsession             = p.mauve,
        harpoon               = p.green,
        lazy                  = p.peach,
        winbar_active         = p.sky,
        winbar_inactive       = p.overlay1,
    }

    -- Keys below become suffixes for highlight groups generated in
    -- statusline.highlights: StlMode<KEY>, StlModeSep<KEY>, StlModeBlock<KEY>,
    -- StlModePos<KEY>, StlChevron<KEY>. NORMAL -> StlModeNORMAL, etc.
    -- If you add a key here, also add it to providers.mode_names so vim
    -- modes can resolve to it.
    M.catpuccin_vi_mode_colors = {
        NORMAL        = p.green,
        OP            = p.sapphire,
        INSERT        = p.mauve,
        VISUAL        = p.flamingo,
        LINES         = p.flamingo,
        BLOCK         = p.maroon,
        REPLACE       = p.maroon,
        ['V-REPLACE'] = p.maroon,
        ENTER         = p.teal,
        MORE          = p.teal,
        SELECT        = p.maroon,
        COMMAND       = p.peach,
        SHELL         = p.green,
        TERM          = p.green,
        NONE          = p.lavender,
    }
else
    M.catpuccin_colors, M.catpuccin_vi_mode_colors = {}, {}
end

-- Active palette — swap to M.catpuccin_* to re-theme.
M.active = {
    colors  = M.tokyonight_colors,
    vi_mode = M.tokyonight_vi_mode_colors,
}

return M
