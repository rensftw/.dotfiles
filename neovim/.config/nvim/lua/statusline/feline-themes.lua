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

return M
