--[[
statusline.winbar

Per-window bar. Shows an optional harpoon badge and the relative file
path with a coloured devicon. Disabled for filetypes / buftypes where a
winbar would be noise (trees, help, terminals, ...).

The active/inactive distinction uses `g:actual_curwin`, which Nvim sets
to the currently focused window id while the statusline/winbar
expression is being evaluated.
]]

local M = {}
local p = require('statusline.providers')

-- Filetypes / buftypes where we don't render a winbar at all.
local disabled_filetypes = {
    NvimTree       = true,
    packer         = true,
    startify       = true,
    fugitive       = true,
    fugitiveblame  = true,
    qf             = true,
    help           = true,
    alpha          = true,
    ['mini-files'] = true,
}
local disabled_buftypes = {
    terminal = true,
    nofile   = true,
}

local function is_disabled()
    return disabled_filetypes[vim.bo.filetype] or disabled_buftypes[vim.bo.buftype]
end

local function is_active_window()
    -- g:actual_curwin is only set while a statusline/winbar is being
    -- evaluated; fall back to "active" if it's missing (e.g. during
    -- setup redraws).
    return vim.g.actual_curwin == nil
        or tonumber(vim.g.actual_curwin) == vim.api.nvim_get_current_win()
end

-- Harpoon badge: '󰛢 <n>' in green for the active window, lavender
-- for inactive. Trailing StlHarpoonSep paints a small colour tail so the
-- badge reads as a chip.
local function harpoon_badge(active)
    local n = p.harpoon()
    if type(n) ~= 'number' then return '' end
    local chip_hl, sep_hl
    if active then
        chip_hl, sep_hl = 'StlHarpoon', 'StlHarpoonSep'
    else
        chip_hl, sep_hl = 'StlWinbarHarpoonInactive', 'StlWinbarHarpoonInactiveSep'
    end
    return ('%%#%s# 󰛢 %d %%#%s#%%*'):format(chip_hl, n, sep_hl)
end

function M.build()
    if is_disabled() then return '' end

    local active = is_active_window()
    local path_hl = active and 'StlWinbarActive' or 'StlWinbarInactive'

    return harpoon_badge(active) .. ' ' .. p.filepath(path_hl)
end

return M
