local M = {}

local winbar_active_left = {
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
