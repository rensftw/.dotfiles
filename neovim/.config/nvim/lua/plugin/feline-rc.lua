-- Feline + Tokyonight
-- https://github.com/dkarter/dotfiles/commit/9f182419392b3875608fd62d70234de92e7973f3
local tokyonight_colors = require('tokyonight.colors').setup { style = 'night' }

local colors = {
    bg = tokyonight_colors.bg_dark,
    fg = tokyonight_colors.fg,
    yellow = tokyonight_colors.yellow,
    cyan = tokyonight_colors.cyan,
    darkblue = tokyonight_colors.fg_gutter,
    green = tokyonight_colors.teal,
    orange = tokyonight_colors.orange,
    violet = tokyonight_colors.magenta,
    magenta = tokyonight_colors.magenta2,
    blue = tokyonight_colors.blue,
    red = tokyonight_colors.red,
    light_bg = tokyonight_colors.bg_highlight,
    primary_blue = tokyonight_colors.blue5,
  }

local vi_mode_colors = {
    NORMAL = colors.green,
    OP = colors.primary_blue,
    INSERT = colors.yellow,
    VISUAL = colors.magenta,
    LINES = colors.magenta,
    BLOCK = colors.magenta,
    REPLACE = colors.red,
    ['V-REPLACE'] = colors.red,
    ENTER = colors.cyan,
    MORE = colors.cyan,
    SELECT = colors.orange,
    COMMAND = colors.blue,
    SHELL = colors.green,
    TERM = colors.green,
    NONE = colors.green,
  }

-- https://github.com/Hitesh-Aggarwal/feline_one_monokai.nvim/blob/2ff798d4d0435d2145593587dc93a70e72a6d279/plugin/feline_one_monokai.lua
local line_ok, feline = pcall(require, "feline")
if not line_ok then
	return
end

local obsession_status = function()
    return vim.fn.ObsessionStatus(' ⟳ ', ' ⏻︎ ')
end

local c = {
	vim_mode = {
        icon = '',
		provider = {
            name = "vi_mode",
			opts = {
				show_mode_name = true,
				-- padding = "center", -- Uncomment for extra padding.
			},
		},
		hl = function()
			return {
				fg = "bg",
                bg = require("feline.providers.vi_mode").get_mode_color(),
				style = "bold",
				name = "NeovimModeHLColor",
			}
		end,
		left_sep = "block",
		right_sep = {
            str =  "right_filled",
            always_visible = true,
            hl = function()
                local background_color = require('feline.providers.git').git_info_exists() and 'darkblue' or 'bg'

                return {
                    fg = require("feline.providers.vi_mode").get_mode_color(),
                    bg = background_color
                }
            end,
        },
	},
	gitBranch = {
		provider = "git_branch",
        hl = {
            bg = "darkblue"
        },
		left_sep = "block",
        right_sep = "block",
	},
	gitDiffAdded = {
		provider = "git_diff_added",
		hl = {
			fg = "green",
		},
		right_sep = "block",
	},
	gitDiffRemoved = {
		provider = "git_diff_removed",
		hl = {
			fg = "red",
		},
		right_sep = "block",
	},
	gitDiffChanged = {
		provider = "git_diff_changed",
		hl = {
            fg = "fg",
		},
		right_sep = "block",
	},
    right_separator = {
        provider = "",
        hl = {
            fg = "fg",
            bg ="darkblue"
        }
    },
    right_separator_filled = {
        provider = "",
        hl = {
            fg = "darkblue",
        }
    },
    left_separator = {
        provider = "",
        enabled = function()
            local diagnostics_exist = require('feline.providers.lsp').diagnostics_exist
            local git_info_exists = require('feline.providers.git').git_info_exists()
            return git_info_exists and diagnostics_exist
        end,
        hl = {
            fg = "darkblue",
        }
    },
    left_separator_filled = {
        provider = " ",
        enabled = function()
            return require('feline.providers.git').git_info_exists()
        end,
        hl = {
            fg = "darkblue",
        }
    },
	fileinfo = {
		provider = {
			name = "file_info",
			opts = {
				type = "unique",
			},
		},
		hl = {
			style = "bold",
		},
		left_sep = " ",
		right_sep = " ",
	},
	diagnostic_errors = {
		provider = "diagnostic_errors",
		hl = {
			fg = "red",
		},
	},
	diagnostic_warnings = {
		provider = "diagnostic_warnings",
		hl = {
			fg = "yellow",
		},
	},
	diagnostic_hints = {
		provider = "diagnostic_hints",
		hl = {
			fg = "aqua",
		},
	},
	diagnostic_info = {
		provider = "diagnostic_info",
		hl = {
			fg = "aqua",
		},
	},
	lsp_client_names = {
		provider = "lsp_client_names",
		hl = {
			fg = "purple",
			bg = "darkblue",
			style = "bold",
		},
		left_sep = "left_filled",
		right_sep = "right_filled",
	},
	obsession_status = {
		provider = obsession_status,
		hl = {
			fg = "violet",
			style = "bold",
		},
        left_sep = "block",
		right_sep = "block",
	},
	file_type = {
		provider = {
			name = "file_type",
			opts = {
				filetype_icon = true,
				case = "titlecase",
			},
		},
		hl = {
			bg = "darkblue",
		},
		left_sep = "block",
		right_sep = "block",
	},
	file_encoding = {
		provider = "file_encoding",
		hl = {
			bg = "darkblue",
		},
		right_sep = "block",
		left_sep = "block",
	},
	position = {
		provider = "position",
		hl = {
			fg = "green",
			bg = "darkblue",
			style = "bold",
		},
		right_sep = "block",
		left_sep = "block",
	},
	line_percentage = {
		provider = "line_percentage",
		hl = {
			fg = "aqua",
			bg = "darkblue",
			style = "bold",
		},
		right_sep = "block",
		left_sep = "block",
	},
	-- scroll_bar = {
	-- 	provider = "scroll_bar",
	-- 	hl = {
	-- 		fg = "yellow",
	-- 		style = "bold",
	-- 	},
	-- },
}

local left = {
	c.vim_mode,
	c.gitBranch,
    c.left_separator_filled,
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
    c.obsession_status,
    c.right_separator_filled,
	c.file_type,
    c.right_separator,
	c.file_encoding,
    c.right_separator,
	c.position,
    c.right_separator,
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
-- feline.winbar.setup()

local winbar = {
    active = {
        {
            {
                provider = {
                    name = "file_info",
                    opts = {
                        type = "relative-short",
                        file_modified_icon = "[+]",
                        colored_icon = true,
                    },
                },
                hl = {
                    fg = "#0db9d7",
                    style = "bold",
                },
            }
        },
        {},
        {},
    },
    inactive = {
        {
            {
                provider = {
                    name = "file_info",
                    opts = {
                        type = "relative-short",
                        file_modified_icon = "[+]",
                        colored_icon = true,
                    },
                },
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
			"^NvimTree$",
		},
		buftypes = {
			"^terminal$",
		},
		bufnames = {},
	},
})
