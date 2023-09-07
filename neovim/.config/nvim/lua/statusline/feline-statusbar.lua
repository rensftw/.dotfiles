local M = {}
local get_mode_color = require('feline.providers.vi_mode').get_mode_color
local git_info_exists = require('feline.providers.git').git_info_exists
local diagnostics_exist = require('feline.providers.lsp').diagnostics_exist

local function git_diff(type)
    local gsd = vim.b.gitsigns_status_dict

    if gsd and gsd[type] and gsd[type] > 0 then
        return tostring(gsd[type])
    end

    return ''
end

local c = {
    vim_mode = {
        icon = '',
        provider = 'vi_mode',
        hl = function()
            return {
                fg = 'background',
                bg = get_mode_color(),
                style = 'bold',
                name = 'NeovimModeHLColor',
            }
        end,
        left_sep = 'block',
        right_sep = {
            {
                str = 'block',
                always_visible = true,
                hl = function()
                    local background_color = git_info_exists() and 'git_branch_background' or 'background'

                    return {
                        fg = get_mode_color(),
                        bg = background_color
                    }
                end,
            },
            {
                str = 'right_filled',
                always_visible = true,
                hl = function()
                    local background_color = git_info_exists() and 'git_branch_background' or 'background'

                    return {
                        fg = get_mode_color(),
                        bg = background_color
                    }
                end,
            }
        },
    },
    gitBranch = {
        provider = 'git_branch',
        hl = {
            bg = 'git_branch_background',
            fg = 'text'
        },
        left_sep = 'block',
        right_sep = {
            'block',
            {
                str = 'right_filled',
                enabled = function()
                    return git_info_exists()
                end,
                hl = {
                    fg = 'git_branch_background'
                }
            },
            {
                str = 'block',
                hl = {
                    fg = 'background'
                }
            }
        },
    },
    gitDiffAdded = {
        provider = function()
            return git_diff('added'), '  '
        end,
        hl = {
            fg = 'git_diff_added',
        },
        right_sep = 'block',
    },
    gitDiffRemoved = {
        provider = function()
            return git_diff('removed'), '  '
        end,
        hl = {
            fg = 'git_diff_removed',
        },
        right_sep = 'block',
    },
    gitDiffChanged = {
        provider = function()
            return git_diff('changed'), '  '
        end,
        hl = {
            fg = 'git_diff_changed',
        },
        right_sep = 'block',
    },
    right_separator_filled = {
        provider = '',
        hl = function()
            return {
                fg = get_mode_color(),
                style = 'bold',
            }
        end,
    },
    left_separator = {
        provider = '',
        enabled = function()
            return git_info_exists() and diagnostics_exist()
        end,
        hl = {
            fg = 'git_branch_background',
        }
    },
    fileinfo = {
        provider = {
            name = 'file_info',
            opts = {
                type = 'unique',
            },
        },
        hl = {
            fg = 'text',
            style = 'bold',
        },
        left_sep = ' ',
        right_sep = ' ',
    },
    diagnostic_errors = {
        provider = 'diagnostic_errors',
        enabled = function()
            return diagnostics_exist(vim.diagnostic.severity.ERROR)
        end,
        hl = {
            fg = 'diagnostic_errors',
        },
    },
    diagnostic_warnings = {
        provider = 'diagnostic_warnings',
        enabled = function()
            return diagnostics_exist(vim.diagnostic.severity.WARN)
        end,
        hl = {
            fg = 'diagnostic_warnings',
        },
    },
    diagnostic_hints = {
        provider = 'diagnostic_hints',
        enabled = function()
            return diagnostics_exist(vim.diagnostic.severity.HINT)
        end,
        hl = {
            fg = 'diagnostic_hints',
        },
    },
    diagnostic_info = {
        provider = 'diagnostic_info',
        enabled = function()
            return diagnostics_exist(vim.diagnostic.severity.INFO)
        end,
        hl = {
            fg = 'diagnostic_info',
        },
    },
    lsp_client_names = {
        provider = 'lsp_client_names',
        enabled = function()
            return diagnostics_exist()
        end,
        hl = {
            fg = 'lsp_text',
            bg = 'lsp_background',
            style = 'bold',
        },
        left_sep = 'left_filled',
        right_sep = 'right_filled',
    },
    obsession_status = {
        provider = function()
            return vim.fn.ObsessionStatus('   ', ' ⏻︎  ')
        end,
        hl = {
            fg = 'obsession',
            style = 'bold',
        },
        right_sep = {
            str = 'left',
            hl = {
                fg = 'git_branch_background',
            }
        },
    },
    harpoon = {
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
            fg = 'harpoon',
            style = 'bold',
        },
        left_sep = 'block',
        right_sep = 'block',
    },
    lazy = {
        provider = function()
            local success, lazy_status = pcall(require, "lazy.status")
            local has_updates = success and lazy_status.has_updates()

            if has_updates then
                return lazy_status.updates()
            else
                return ''
            end
        end,
        hl = {
            fg = 'lazy',
            style = 'bold',
        },
        left_sep = 'block',
        right_sep = 'block',
    },
    file_type = {
        provider = {
            name = 'file_type',
            opts = {
                filetype_icon = true,
                case = 'titlecase',
            },
        },
        hl = {
            fg = 'text',
        },
        left_sep = 'block',
        right_sep = {
            'block',
            {
                str = 'left',
                hl = {
                    fg = 'git_branch_background',
                }
            }
        },
    },
    file_encoding = {
        provider = 'file_encoding',
        hl = {
            fg = 'text',
        },
        right_sep = {
            'block',
            {
                provider = '',
                hl = {
                    fg = 'git_branch_background',
                }
            }
        },
        left_sep = 'block',
    },
    position = {
        provider = 'position',
        hl = function()
            return {
                fg = 'inverted_text',
                bg = get_mode_color(),
                style = 'bold',
            }
        end,
        right_sep = 'block',
        left_sep = 'block',
    },
    line_percentage = {
        provider = 'line_percentage',
        hl = function()
            return {
                fg = 'inverted_text',
                bg = get_mode_color(),
                style = 'bold',
            }
        end,
        right_sep = 'block',
        left_sep = 'block',
    },
    scroll_bar = {
        provider = 'scroll_bar',
        hl = {
            fg = 'yellow',
            style = 'bold',
        },
    },
}

local statusbar_left = {
    c.vim_mode,
    c.gitBranch,
    c.gitDiffAdded,
    c.gitDiffChanged,
    c.gitDiffRemoved,
    c.left_separator,
    c.diagnostic_errors,
    c.diagnostic_warnings,
    c.diagnostic_info,
    c.diagnostic_hints,
}

local statusbar_middle = {
    -- c.fileinfo,
    -- c.diagnostic_errors,
    -- c.diagnostic_warnings,
    -- c.diagnostic_info,
    -- c.diagnostic_hints,
    -- c.lsp_client_names
}

local statusbar_right = {
    -- c.lsp_client_names,
    c.lazy,
    c.harpoon,
    c.obsession_status,
    c.file_type,
    c.file_encoding,
    c.right_separator_filled,
    c.position,
    c.line_percentage,
    -- c.scroll_bar,
}

M.components = {
    active = {
        statusbar_left,
        statusbar_middle,
        statusbar_right,
    },
    inactive = {
        statusbar_left,
        -- statusbar_middle,
        statusbar_right,
    },
}

return M
