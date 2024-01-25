local M = {}

local success, tokyonight_theme = pcall(require, 'tokyonight.colors')
if success then
    local tokyonight_palette = tokyonight_theme.setup({ style = 'night' })

    M.tokyonight_colors = {
        bg                    = tokyonight_palette.bg_dark,
        background            = tokyonight_palette.bg_dark,
        text                  = tokyonight_palette.fg,
        inverted_text         = tokyonight_palette.bg_dark,
        git_branch_background = tokyonight_palette.fg_gutter,
        git_diff_added        = tokyonight_palette.teal,
        git_diff_removed      = tokyonight_palette.red,
        git_diff_changed      = tokyonight_palette.fg,
        diagnostic_errors     = tokyonight_palette.red,
        diagnostic_warnings   = tokyonight_palette.yellow,
        diagnostic_info       = tokyonight_palette.cyan,
        diagnostic_hints      = tokyonight_palette.cyan,
        lsp_text              = tokyonight_palette.green1,
        lsp_background        = tokyonight_palette.fg_gutter,
        obsession             = tokyonight_palette.magenta,
        harpoon               = tokyonight_palette.green1,
        lazy                  = tokyonight_palette.orange,
    }

    M.tokyonight_vi_mode_colors = {
        NORMAL        = tokyonight_palette.teal,
        OP            = tokyonight_palette.blue5,
        INSERT        = tokyonight_palette.yellow,
        VISUAL        = tokyonight_palette.magenta2,
        LINES         = tokyonight_palette.magenta2,
        BLOCK         = tokyonight_palette.magenta2,
        REPLACE       = tokyonight_palette.red,
        ['V-REPLACE'] = tokyonight_palette.red,
        ENTER         = tokyonight_palette.cyan,
        MORE          = tokyonight_palette.cyan,
        SELECT        = tokyonight_palette.orange,
        COMMAND       = tokyonight_palette.blue,
        SHELL         = tokyonight_palette.teal,
        TERM          = tokyonight_palette.teal,
        NONE          = tokyonight_palette.teal,
    }
else
    M.tokyonight_colors = {}
    M.tokyonight_vi_mode_colors = {}
end

local success, catpuccin_theme = pcall(require, 'catppuccin.palettes')
if (success) then
    local catpuccin_palette = catpuccin_theme.get_palette()

    M.catpuccin_colors = {
        bg                    = catpuccin_palette.base,
        background            = catpuccin_palette.base,
        text                  = catpuccin_palette.text,
        inverted_text         = catpuccin_palette.base,
        git_branch_background = catpuccin_palette.surface1,
        git_diff_added        = catpuccin_palette.green,
        git_diff_removed      = catpuccin_palette.red,
        git_diff_changed      = catpuccin_palette.subtext1,
        diagnostic_errors     = catpuccin_palette.red,
        diagnostic_warnings   = catpuccin_palette.peach,
        diagnostic_info       = catpuccin_palette.sky,
        diagnostic_hints      = catpuccin_palette.sapphire,
        lsp_text              = catpuccin_palette.teal,
        lsp_background        = catpuccin_palette.surface0,
        obsession             = catpuccin_palette.mauve,
        harpoon               = catpuccin_palette.green,
        lazy                  = catpuccin_palette.peach,
    }

    M.catpuccin_vi_mode_colors = {
        NORMAL        = catpuccin_palette.green,
        INSERT        = catpuccin_palette.mauve,
        VISUAL        = catpuccin_palette.flamingo,
        LINES         = catpuccin_palette.flamingo,
        BLOCK         = catpuccin_palette.maroon,
        REPLACE       = catpuccin_palette.maroon,
        ['V-REPLACE'] = catpuccin_palette.maroon,
        ENTER         = catpuccin_palette.teal,
        MORE          = catpuccin_palette.teal,
        SELECT        = catpuccin_palette.maroon,
        COMMAND       = catpuccin_palette.peach,
        SHELL         = catpuccin_palette.green,
        TERM          = catpuccin_palette.green,
        NONE          = catpuccin_palette.lavender,
    }
else
    M.catpuccin_colors = {}
    M.catpuccin_vi_mode_colors = {}
end

local success, flexoki_theme = pcall(require, 'flexoki.palette')
if (success) then
    -- local flexoki_palette = flexoki_theme.setup({ variant = 'dark' })
    local flexoki_palette = {
        ['flexoki-black']       = '#100F0F',
        ['flexoki-paper']       = '#FFFCF0',

        ['flexoki-950']         = '#1C1B1A',
        ['flexoki-900']         = '#282726',
        ['flexoki-850']         = '#343331',
        ['flexoki-800']         = '#403E3C',
        ['flexoki-700']         = '#575653',
        ['flexoki-600']         = '#6F6E69',
        ['flexoki-500']         = '#878580',
        ['flexoki-300']         = '#B7B5AC',
        ['flexoki-200']         = '#CECDC3',
        ['flexoki-150']         = '#DAD8CE',
        ['flexoki-100']         = '#E6E4D9',
        ['flexoki-50']          = '#F2F0E5',

        ['flexoki-red-600']     = '#AF3029',
        ['flexoki-red-400']     = '#D14D41',

        ['flexoki-orange-600']  = '#BC5215',
        ['flexoki-orange-400']  = '#DA702C',

        ['flexoki-yellow-900']  = '#4D3A0B',
        ['flexoki-yellow-600']  = '#AD8301',
        ['flexoki-yellow-400']  = '#D0A215',
        ['flexoki-yellow-100']  = '#FCEEB8',

        ['flexoki-green-600']   = '#66800B',
        ['flexoki-green-400']   = '#879A39',

        ['flexoki-cyan-950']    = '#142625',
        ['flexoki-cyan-600']    = '#24837B',
        ['flexoki-cyan-400']    = '#3AA99F',
        ['flexoki-cyan-50']     = '#EBF2E7',

        ['flexoki-blue-600']    = '#205EA6',
        ['flexoki-blue-400']    = '#4385BE',

        ['flexoki-purple-600']  = '#5E409D',
        ['flexoki-purple-400']  = '#8B7EC8',

        ['flexoki-magenta-600'] = '#A02F6F',
        ['flexoki-magenta-400'] = '#CE5D97',
    }

    M.flexoki_colors = {
        bg                    = flexoki_palette['flexoki-black'],
        background            = flexoki_palette['flexoki-black'],
        text                  = flexoki_palette['flexoki-100'],
        inverted_text         = flexoki_palette['flexoki-950'],
        git_branch_background = flexoki_palette['flexoki-700'],
        git_diff_added        = flexoki_palette['flexoki-green-400'],
        git_diff_removed      = flexoki_palette['flexoki-red-600'],
        git_diff_changed      = flexoki_palette['flexoki-purple-400'],
        diagnostic_errors     = flexoki_palette['flexoki-red-600'],
        diagnostic_warnings   = flexoki_palette['flexoki-yellow-400'],
        diagnostic_info       = flexoki_palette['flexoki-blue-400'],
        diagnostic_hints      = flexoki_palette['flexoki-cyan-400'],
        lsp_text              = flexoki_palette['flexoki-cyan-600'],
        lsp_background        = flexoki_palette['flexoki-700'],
        obsession             = flexoki_palette['flexoki-purple-400'],
        harpoon               = flexoki_palette['flexoki-magenta-400'],
        lazy                  = flexoki_palette['flexoki-orange-400'],
    }

    M.flexoki_vi_mode_colors = {
        NORMAL        = flexoki_palette['flexoki-blue-400'],
        INSERT        = flexoki_palette['flexoki-yellow-400'],
        VISUAL        = flexoki_palette['flexoki-magenta-600'],
        LINES         = flexoki_palette['flexoki-magenta-600'],
        BLOCK         = flexoki_palette['flexoki-purple-400'],
        REPLACE       = flexoki_palette['flexoki-purple-400'],
        ['V-REPLACE'] = flexoki_palette['flexoki-purple-400'],
        ENTER         = flexoki_palette['flexoki-cyan-600'],
        MORE          = flexoki_palette['flexoki-cyan-600'],
        SELECT        = flexoki_palette['flexoki-purple-400'],
        COMMAND       = flexoki_palette['flexoki-orange-600'],
        SHELL         = flexoki_palette['flexoki-green-600'],
        TERM          = flexoki_palette['flexoki-green-600'],
        NONE          = flexoki_palette['flexoki-yellow-100'],
    }
else
    M.flexoki_colors = {}
    M.flexoki_colors = {}
end

return M
