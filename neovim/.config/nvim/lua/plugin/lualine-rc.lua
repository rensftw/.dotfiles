-- Color table for highlights
-- stylua: ignore
local colors = {
    bg       = '#202328',
    fg       = '#bbc2cf',
    yellow   = '#ECBE7B',
    cyan     = '#008080',
    darkblue = '#081633',
    green    = '#98be65',
    orange   = '#FF8800',
    violet   = '#a9a1e1',
    magenta  = '#c678dd',
    blue     = '#51afef',
    red      = '#ec5f67',
}

-- Reuse git info from gitsigns.nvim
-- This is a temporary fix for:
-- https://github.com/nvim-lualine/lualine.nvim/issues/699
local function diff_source()
    local gitsigns = vim.b.gitsigns_status_dict
    if gitsigns then
        return {
            added = gitsigns.added,
            modified = gitsigns.changed,
            removed = gitsigns.removed
        }
    end
end

local obsession = {
    component = function()
        return vim.fn.ObsessionStatus('⟳ ', '⏻︎')
    end
}

local harpoon = {
    component = function()
        local harpoon_number = require("harpoon.mark").get_index_of(vim.fn.bufname())
        if harpoon_number then
            return "ﯠ " .. harpoon_number
        else
            return "ﯡ "
        end
    end,
    color = function()
        if require('harpoon.mark').get_index_of(vim.fn.bufname()) then
            return { fg = "#98be65", gui = 'bold' }
        else
            return { fg = "#ec5f67" }
        end
    end
}


require('lualine').setup {
    options = {
        icons_enabled = true,
        -- theme = 'auto',
        theme = 'tokyonight',
        component_separators = { left = '', right = '' },
        section_separators = { left = '', right = '' },
        disabled_filetypes = {},
        always_divide_middle = true,
    },
    sections = {
        lualine_a = { 'mode' },
        lualine_b = {
            'branch',
            {
                'diagnostics',
                sources = { 'nvim_diagnostic', 'coc' },
                symbols = { error = ' ', warn = ' ', info = ' ' },
                diagnostics_color = {
                    color_error = { fg = colors.red },
                    color_warn = { fg = colors.yellow },
                    color_info = { fg = colors.cyan },
                },
            }
        },
        lualine_c = { { 'diff', source = diff_source } },
        lualine_x = { 'filetype', 'fileformat', 'encoding' },
        lualine_y = { 'progress' },
        lualine_z = { 'location' }
    },
    inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = { 'filename' },
        lualine_x = { 'location' },
        lualine_y = {},
        lualine_z = {}
    },
    tabline = {
        lualine_a = {
            {
                'filename',
                path = 1, -- Shows relative path
            }
        },
        lualine_x = { { harpoon.component, color = harpoon.color } },
        lualine_y = { { obsession.component } },
        lualine_z = { 'tabs' },
    },
    extensions = {
        'quickfix',
        'fugitive',
        'nvim-tree',
    },
}
