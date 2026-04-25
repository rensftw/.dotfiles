--[[
statusline.providers

Each public function returns a ready-to-render statusline fragment (or
an empty string if the segment has nothing to show, so the divider
helper in statusbar.lua / winbar.lua can drop it cleanly).

Notes on the format-string dialect used below:
  %%          → literal `%` after :format()
  %#Group#    → switch highlight group
  %*          → reset to the default statusline highlight
  %l %c %p    → cursor line / column / percentage (evaluated lazily by Nvim)

Highlight groups (StlXxx) are declared once in statusline.highlights and
are re-applied on every :ColorScheme.
]]

local M = {}

-- =====================================================================
-- Mode
-- =====================================================================

-- vim.fn.mode(1) returns the "long" code (e.g. 'niI' for Insert-inside-
-- Normal). We collapse the 30+ possibilities to 15 palette keys that
-- correspond to the vi_mode_colors table in statusline.themes.
--
-- vim.keycode('<C-v>') / vim.keycode('<C-s>') resolve to the literal
-- control characters that Neovim returns from mode() for the
-- block-wise visual/select variants.
local CTRL_V = vim.keycode('<C-v>')  -- visual-block mode code
local CTRL_S = vim.keycode('<C-s>')  -- select-block mode code

local mode_names = {
    ['n']           = 'NORMAL',
    ['niI']         = 'NORMAL',
    ['niR']         = 'NORMAL',
    ['niV']         = 'NORMAL',
    ['nt']          = 'NORMAL',
    ['no']          = 'OP',
    ['nov']         = 'OP',
    ['noV']         = 'OP',
    ['no' .. CTRL_V]= 'OP',
    ['v']           = 'VISUAL',
    ['vs']          = 'VISUAL',
    ['V']           = 'LINES',
    ['Vs']          = 'LINES',
    [CTRL_V]        = 'BLOCK',
    [CTRL_V .. 's'] = 'BLOCK',
    ['s']           = 'SELECT',
    ['S']           = 'SELECT',
    [CTRL_S]        = 'SELECT',
    ['i']           = 'INSERT',
    ['ic']          = 'INSERT',
    ['ix']          = 'INSERT',
    ['R']           = 'REPLACE',
    ['Rc']          = 'REPLACE',
    ['Rx']          = 'REPLACE',
    ['Rv']          = 'V-REPLACE',
    ['Rvc']         = 'V-REPLACE',
    ['Rvx']         = 'V-REPLACE',
    ['c']           = 'COMMAND',
    ['cv']          = 'COMMAND',
    ['ce']          = 'COMMAND',
    ['r']           = 'ENTER',
    ['r?']          = 'ENTER',
    ['rm']          = 'MORE',
    ['!']           = 'SHELL',
    ['t']           = 'TERM',
}

function M.mode_name()
    return mode_names[vim.fn.mode(1)] or 'NONE'
end

function M.mode()
    local name = M.mode_name()
    -- Highlight groups are generated per mode in statusline.highlights from
    -- the vi_mode palette in statusline.themes. For NORMAL mode the names
    -- below resolve to StlModeNORMAL / StlModeSepNORMAL / StlModeBlockNORMAL.
    local mode_hl = 'StlMode' .. name -- label block: fg=bg colour, bg=mode colour
    -- Trailing  slant bleeds the mode colour into whatever follows.
    -- When git info follows, that bg = git_branch_background (StlModeSep*);
    -- otherwise the slant sits on the transparent statusline (StlModeBlock*).
    local slant_hl = M.has_git_info()
        and ('StlModeSep' .. name)
        or ('StlModeBlock' .. name)
    return ('%%#%s#  %s %%#%s#%%*'):format(mode_hl, name, slant_hl)
end

-- =====================================================================
-- State queries
-- Used by the conditional separators and by mode() to pick its slant bg.
-- =====================================================================

function M.has_git_info()
    local s = vim.b.gitsigns_status_dict
    return s ~= nil and s.head ~= nil and s.head ~= ''
end

function M.has_diagnostics()
    return #vim.diagnostic.get(0) > 0
end

-- =====================================================================
-- Git  (all fields come from vim.b.gitsigns_status_dict)
-- =====================================================================

function M.git_branch()
    if not M.has_git_info() then return '' end
    -- '  head ' on git_branch_background, ending with a  slant
    -- back onto the transparent statusline.
    return ('%%#StlGitBg#  %s %%#StlGitSep#%%*'):format(vim.b.gitsigns_status_dict.head)
end

function M.git_diff()
    local s = vim.b.gitsigns_status_dict
    if not s then return '' end
    local parts = {}
    if (s.added or 0) > 0 then parts[#parts + 1] = ('%%#StlDiffAdd#  %d %%*'):format(s.added) end
    if (s.changed or 0) > 0 then parts[#parts + 1] = ('%%#StlDiffChg#  %d %%*'):format(s.changed) end
    if (s.removed or 0) > 0 then parts[#parts + 1] = ('%%#StlDiffDel#  %d %%*'):format(s.removed) end
    return table.concat(parts)
end

-- =====================================================================
-- Separators
-- =====================================================================

-- Thin  between the git cluster and diagnostics. Only rendered
-- when both are present — otherwise we'd get a dangling tick.
function M.left_separator()
    if M.has_git_info() and M.has_diagnostics() then
        return '%#StlLeftSep# %*'
    end
    return ''
end

-- Thin  placed between adjacent right-side segments.
-- Always the same string; statusbar.join_with_divider decides when to emit.
function M.right_divider()
    return '%#StlRightDivider#  %*'
end

function M.right_chevron()
    -- StlChevron<mode> (generated in statusline.highlights) — filled 
    -- in the current mode's colour, marking the boundary before the
    -- mode-coloured position/percent block.
    local chevron_hl = 'StlChevron' .. M.mode_name()
    return ('%%#%s#%%*'):format(chevron_hl)
end

-- =====================================================================
-- Diagnostics
-- Icons come from vim.diagnostic.config().signs.text so the statusline
-- stays in sync with whatever the user configured in native-lsp-settings.
-- =====================================================================

function M.diagnostics()
    local sev       = vim.diagnostic.severity
    local cfg_signs = (vim.diagnostic.config() or {}).signs
    local signs_tbl = type(cfg_signs) == 'table' and cfg_signs or {}
    local icons     = signs_tbl.text or {}
    local texthls   = signs_tbl.texthl or {}

    -- Preferred: the theme's base Diagnostic<Severity> groups. Every modern
    -- colorscheme (tokyonight, catppuccin, …) defines these. Fall back to
    -- the user's vim.diagnostic.config().signs.texthl mapping (from
    -- core/native-lsp-settings.lua) only if the theme group is missing.
    local theme_hl  = {
        [sev.ERROR] = 'DiagnosticError',
        [sev.WARN]  = 'DiagnosticWarn',
        [sev.INFO]  = 'DiagnosticInfo',
        [sev.HINT]  = 'DiagnosticHint',
    }

    local function resolve_hl(level)
        local base = theme_hl[level]
        if vim.fn.hlexists(base) == 1 then
            return base
        end
        return texthls[level] or base
    end

    local out = {}
    for _, level in ipairs({ sev.ERROR, sev.WARN, sev.INFO, sev.HINT }) do
        local n = #vim.diagnostic.get(0, { severity = level })
        if n > 0 then
            out[#out + 1] = ('%%#%s# %s %d %%*'):format(resolve_hl(level), icons[level] or '', n)
        end
    end
    return table.concat(out)
end

-- =====================================================================
-- Plugin indicators
-- =====================================================================

-- vim-obsession: floppy glyph while recording, power glyph when idle.
-- The plugin loads lazily on :Obsession, so ObsessionStatus may not
-- exist yet — return '' in that case so surrounding dividers collapse.
function M.obsession()
    if vim.fn.exists('*ObsessionStatus') == 0 then return '' end
    local s = vim.fn.ObsessionStatus('   ', ' ⏻︎  ')
    if s == '' then return '' end
    return '%#StlObsession#' .. s .. '%*'
end

function M.lazy_updates()
    local ok, status = pcall(require, 'lazy.status')
    if not ok or not status.has_updates() then return '' end
    return ('%%#StlLazy# %s %%*'):format(status.updates())
end

-- Harpoon index for the current buffer (winbar only).
-- Returns the mark number, or nil if the buffer isn't in the list.
function M.harpoon()
    local ok, mark = pcall(require, 'harpoon.mark')
    if not ok then return nil end
    return mark.get_index_of(vim.fn.bufname())
end

-- =====================================================================
-- File info
-- =====================================================================

-- devicons.get_icon_by_filetype returns (glyph, 'DevIcon<Name>' hl group)
-- so the icon keeps its per-filetype colour while the label uses the
-- neutral text colour.
function M.filetype()
    local ft = vim.bo.filetype
    if ft == '' then return '' end
    local label = ft:sub(1, 1):upper() .. ft:sub(2)
    local icon, icon_hl = require('nvim-web-devicons').get_icon_by_filetype(ft, { default = true })
    if not icon then
        return ('%%#StlFileType# %s %%*'):format(label)
    end
    return ('%%#%s# %s %%#StlFileType#%s %%*'):format(icon_hl or 'StlFileType', icon, label)
end

function M.encoding()
    local enc = vim.bo.fileencoding
    if enc == '' then return '' end
    return ('%%#StlEncoding# %s %%*'):format(enc)
end

-- Relative path with colored devicon, used by the winbar.
-- `text_hl` lets the caller distinguish active vs inactive windows.
function M.filepath(text_hl)
    local path = vim.fn.expand('%:.')
    if path == '' then return '[No Name]' end
    text_hl = text_hl or 'StlBase'
    local modified = vim.bo.modified and ' [+]' or ''
    local icon, icon_hl = require('nvim-web-devicons').get_icon_by_filetype(vim.bo.filetype, { default = true })
    if not icon then
        return ('%%#%s#%s%s%%*'):format(text_hl, path, modified)
    end
    return ('%%#%s#%s %%#%s#%s%s%%*'):format(icon_hl or text_hl, icon, text_hl, path, modified)
end

-- =====================================================================
-- Cursor position  (mode-coloured; Nvim evaluates %l/%c/%p lazily)
-- =====================================================================

-- StlModePos<mode> (generated in statusline.highlights) paints the cursor
-- position and percentage blocks in the current mode's colour.
function M.position()
    local pos_hl = 'StlModePos' .. M.mode_name()
    return ('%%#%s# %%l:%%c %%*'):format(pos_hl)
end

function M.percent()
    local pos_hl = 'StlModePos' .. M.mode_name()
    return ('%%#%s# %%p%%%% %%*'):format(pos_hl)
end

return M
