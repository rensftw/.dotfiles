--[[
statusline.statusbar

Assembles the full statusline expression. Called once per redraw via
  vim.go.statusline = "%{%v:lua.require'statusline.statusbar'.build()%}"

Layout (laststatus=3, single global bar):
  left  = mode → git branch → git diff → [leftsep] → diagnostics
  right = lazy/obsession/filetype/encoding (divider-joined) → chevron → pos → percent
]]

local M = {}
local p = require('statusline.providers')

-- Emit `divider` only between non-empty neighbours, so sections that
-- return '' (no lazy updates, no obsession session, ...) don't leave
-- dangling dividers behind.
local function join_with_divider(parts, divider)
    local out = {}
    for _, part in ipairs(parts) do
        if part ~= '' then
            if #out > 0 then out[#out+1] = divider end
            out[#out+1] = part
        end
    end
    return table.concat(out)
end

function M.build()
    local left = table.concat({
        p.mode(),
        p.git_branch(),
        p.git_diff(),
        p.left_separator(),
        p.diagnostics(),
    })

    local middle_right = join_with_divider({
        p.lazy_updates(),
        p.obsession(),
        p.filetype(),
        p.encoding(),
    }, p.right_divider())

    local right = middle_right .. p.right_chevron() .. p.position() .. p.percent()

    -- %=  right-aligns everything that follows.
    return left .. '%=' .. right
end

return M
