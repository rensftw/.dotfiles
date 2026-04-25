--[[
statusline.highlights

Defines every StlXxx highlight group consumed by statusline.providers.
Called once at setup and re-applied on :ColorScheme so palette switches
(e.g. tokyonight → catppuccin) propagate.

Naming conventions
------------------
  StlBase, StlGitBg, StlGitSep, …        static segments
  StlDiffAdd / Chg / Del                 git diff counters
  StlDiagErr / Warn / Info / Hint        diagnostics
  StlLeftSep, StlRightDivider            inline separators
  StlLazy, StlObsession, StlFileType, …  plugin / file-info segments
  StlWinbar*, StlHarpoon*                winbar styling

Mode-dependent groups (one per entry in the vi_mode palette):
  StlMode<NAME>       label block  (fg = bg colour, bg = mode colour)
  StlModeSep<NAME>    mode → git slant   (fg = mode, bg = git_branch_bg)
  StlModeBlock<NAME>  mode → transparent slant
  StlModePos<NAME>    mode-coloured position / percent block
  StlChevron<NAME>    mode-coloured filled chevron before position

Omitting `bg` makes the group inherit the StatusLine / WinBar background,
which is what tokyonight's transparent=true relies on.
]]

local M = {}

local function set(name, spec)
    vim.api.nvim_set_hl(0, name, spec)
end

function M.setup()
    local themes = require('statusline.themes')
    local c  = themes.active.colors
    local vi = themes.active.vi_mode

    -- Static segments ------------------------------------------------
    set('StlBase',         { fg = c.text })
    set('StlGitBg',        { fg = c.text, bg = c.git_branch_background })
    set('StlGitSep',       { fg = c.git_branch_background })
    set('StlLeftSep',      { fg = c.git_branch_background })
    set('StlRightDivider', { fg = c.git_branch_background })

    set('StlDiffAdd',  { fg = c.git_diff_added })
    set('StlDiffChg',  { fg = c.git_diff_changed })
    set('StlDiffDel',  { fg = c.git_diff_removed })

    set('StlDiagErr',  { fg = c.diagnostic_errors })
    set('StlDiagWarn', { fg = c.diagnostic_warnings })
    set('StlDiagInfo', { fg = c.diagnostic_info })
    set('StlDiagHint', { fg = c.diagnostic_hints })

    set('StlLazy',      { fg = c.lazy,      bold = true })
    set('StlObsession', { fg = c.obsession, bold = true })
    set('StlFileType',  { fg = c.text })
    set('StlEncoding',  { fg = c.text })

    -- Winbar ---------------------------------------------------------
    set('StlHarpoon',                  { fg = c.inverted_text, bg = c.harpoon,         bold = true })
    set('StlHarpoonSep',               { fg = c.harpoon })
    set('StlWinbarActive',             { fg = c.winbar_active,   bold = true })
    set('StlWinbarInactive',           { fg = c.winbar_inactive, bold = true })
    set('StlWinbarHarpoonInactive',    { fg = c.inverted_text, bg = c.winbar_inactive, bold = true })
    set('StlWinbarHarpoonInactiveSep', { fg = c.winbar_inactive })

    -- Mode-dependent groups ------------------------------------------
    for name, color in pairs(vi) do
        set('StlMode'      .. name, { fg = c.background,    bg = color,                  bold = true })
        set('StlModeSep'   .. name, { fg = color,           bg = c.git_branch_background })
        set('StlModeBlock' .. name, { fg = color })
        set('StlModePos'   .. name, { fg = c.inverted_text, bg = color,                  bold = true })
        set('StlChevron'   .. name, { fg = color,                                       bold = true })
    end
end

return M
