local line_ok, feline = pcall(require, 'feline')
if not line_ok then
	return
end

local get_mode_color = require('feline.providers.vi_mode').get_mode_color
local git_info_exists = require('feline.providers.git').git_info_exists
local function git_diff(type)
    local gsd = vim.b.gitsigns_status_dict

    if gsd and gsd[type] and gsd[type] > 0 then
        return tostring(gsd[type])
    end

    return ''
end

-- Feline + Tokyonight
local tokyonight_colors = require('tokyonight.colors').setup { style = 'night' }

local colors = {
    bg           = tokyonight_colors.bg_dark,
    fg           = tokyonight_colors.fg,
    yellow       = tokyonight_colors.yellow,
    cyan         = tokyonight_colors.cyan,
    darkblue     = tokyonight_colors.fg_gutter,
    green        = tokyonight_colors.teal,
    orange       = tokyonight_colors.orange,
    violet       = tokyonight_colors.magenta,
    magenta      = tokyonight_colors.magenta2,
    blue         = tokyonight_colors.blue,
    red          = tokyonight_colors.red,
    light_bg     = tokyonight_colors.bg_highlight,
    primary_blue = tokyonight_colors.blue5,
  }

local vi_mode_colors = {
    NORMAL        = colors.green,
    OP            = colors.primary_blue,
    INSERT        = colors.yellow,
    VISUAL        = colors.magenta,
    LINES         = colors.magenta,
    BLOCK         = colors.magenta,
    REPLACE       = colors.red,
    ['V-REPLACE'] = colors.red,
    ENTER         = colors.cyan,
    MORE          = colors.cyan,
    SELECT        = colors.orange,
    COMMAND       = colors.blue,
    SHELL         = colors.green,
    TERM          = colors.green,
    NONE          = colors.green,
  }

local c = {
	vim_mode = {
        icon = '',
		provider = 'vi_mode',
		hl = function()
			return {
				fg = 'bg',
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
                    local background_color = git_info_exists() and 'darkblue' or 'bg'

                    return {
                        fg = get_mode_color(),
                        bg = background_color
                    }
                end,
            },
            {
                str =  'right_filled',
                always_visible = true,
                hl = function()
                    local background_color = git_info_exists() and 'darkblue' or 'bg'

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
            bg = 'darkblue'
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
                    fg = 'darkblue',
                }
            },
            {
                str = 'block',
                hl = {
                    fg = 'bg'
                }
            }
        },
	},
	gitDiffAdded = {
		provider = function ()
		  return git_diff('added'), '  '
		end,
		hl = {
			fg = 'green',
		},
		right_sep = 'block',
	},
	gitDiffRemoved = {
		provider = function ()
            return git_diff('removed'), '  '
		end,
		hl = {
			fg = 'red',
		},
		right_sep = 'block',
	},
	gitDiffChanged = {
		provider = function ()
            return git_diff('changed'), '  '
		end,
		hl = {
            fg = 'fg',
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
            local diagnostics_exist = require('feline.providers.lsp').diagnostics_exist
            return git_info_exists() and diagnostics_exist
        end,
        hl = {
            fg = 'darkblue',
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
			style = 'bold',
		},
		left_sep = ' ',
		right_sep = ' ',
	},
	diagnostic_errors = {
		provider = 'diagnostic_errors',
		hl = {
			fg = 'red',
		},
	},
	diagnostic_warnings = {
		provider = 'diagnostic_warnings',
		hl = {
			fg = 'yellow',
		},
	},
	diagnostic_hints = {
		provider = 'diagnostic_hints',
		hl = {
			fg = 'aqua',
		},
	},
	diagnostic_info = {
		provider = 'diagnostic_info',
		hl = {
			fg = 'aqua',
		},
	},
	lsp_client_names = {
		provider = 'lsp_client_names',
		hl = {
			fg = tokyonight_colors.green1,
			bg = 'darkblue',
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
			fg = 'violet',
			style = 'bold',
		},
		right_sep = {
            str =  'left',
            hl = {
                fg = 'darkblue'
            }
        },
	},
	harpoon = {
		provider = function()
            local harpoon_number = require('harpoon.mark').get_index_of(vim.fn.bufname())
            if harpoon_number then
                return 'ﯠ ' .. harpoon_number
            else
                return ''
            end
		end,
		hl = {
			fg = 'green',
			style = 'bold',
		},
        left_sep = 'block',
		right_sep = {
            'block',
            {
                str =  'left',
                hl = {
                    fg = 'darkblue'
                }
            }
        },
	},
	file_type = {
		provider = {
			name = 'file_type',
			opts = {
				filetype_icon = true,
				case = 'titlecase',
			},
		},
		left_sep = 'block',
		right_sep = {
            'block',
            {
                str =  'left',
                hl = {
                    fg = 'darkblue'
                }
            }
        },
	},
	file_encoding = {
		provider = 'file_encoding',
        right_sep = {
            'block',
            {
                provider = '',
                hl = {
                    fg = 'darkblue',
                }
            }
        },
		left_sep = 'block',
	},
	position = {
		provider = 'position',
		hl = function()
			return {
				fg = 'bg',
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
				fg = 'bg',
                bg = require('feline.providers.vi_mode').get_mode_color(),
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

local left = {
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

local middle = {
	-- c.fileinfo,
	c.diagnostic_errors,
	c.diagnostic_warnings,
	c.diagnostic_info,
	c.diagnostic_hints,
}

local right = {
	-- c.lsp_client_names,
    c.harpoon,
    c.obsession_status,
	c.file_type,
	c.file_encoding,
    c.right_separator_filled,
	c.position,
	c.line_percentage,
	-- c.scroll_bar,
}

local components = {
	active = {
		left,
		-- middle,
		right,
	},
	inactive = {
		left,
		-- middle,
		right,
	},
}

feline.setup({
	components = components,
	theme = colors,
	vi_mode_colors = vi_mode_colors,
})

local winbar = {
    active = {
        {
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
        },
        {},
        {},
    },
    inactive = {
        {
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
        },
        {},
        {},
    },
}

feline.winbar.setup({
    components = winbar,
	disable = {
		filetypes = {
            '^NvimTree$',
            '^packer$',
            '^startify$',
            '^fugitive$',
            '^fugitiveblame$',
            '^qf$',
            '^help$',
		},
		buftypes = {
			'^terminal$',
		},
		bufnames = {},
	},
})
