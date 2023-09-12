local M = {}

local winbar_active_left = {
    {
        provider = function()
            local success, harpoon_mark = pcall(require, 'harpoon.mark')
            local harpoon_number = success and harpoon_mark.get_index_of(vim.fn.bufname()) or nil
            if harpoon_number then
                return '󰛢 ' .. harpoon_number
            else
                return ''
            end
        end,
        hl = {
            fg = 'inverted_text',
            bg = 'harpoon',
            style = 'bold',
        },
        left_sep = 'slant_left',
        right_sep = 'slant_right_2',
    },
    {
        provider = {
            name = 'file_info',
            opts = {
                type = 'relative',
                file_modified_icon = '[+]',
                colored_icon = true,
            },
        },
        hl = {
            fg = '#0db9d7',
            style = 'bold',
        },
        left_sep = ' '
    }
}

local winbar_inactive_left = {
    {
        provider = function()
            local success, harpoon_mark = pcall(require, 'harpoon.mark')
            local harpoon_number = success and harpoon_mark.get_index_of(vim.fn.bufname()) or nil
            if harpoon_number then
                return '󰛢 ' .. harpoon_number
            else
                return ''
            end
        end,
        hl = {
            fg = 'inverted_text',
            bg = '#a9b1d6',
            style = 'bold',
        },
        left_sep = 'slant_left',
        right_sep = 'slant_right_2',
    },
    {
        provider = {
            name = 'file_info',
            opts = {
                type = 'relative',
                file_modified_icon = '[+]',
                colored_icon = true,
            },
        },
        hl = {
            fg = '#a9b1d6',
            style = 'bold',
        },
        left_sep = ' '
    }
}

local winbar_middle = {}
local winbar_right = {}

M.components = {
    active = {
        winbar_active_left,
        winbar_middle,
        winbar_right,
    },
    inactive = {
        winbar_inactive_left,
        winbar_middle,
        winbar_right,
    },
}
return M
