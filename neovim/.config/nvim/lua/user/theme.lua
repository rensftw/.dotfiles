-- require('tokyonight').setup({
--     style = 'night',
--     transparent = true,
--     dim_inactive = true,
--     hide_inactive_statusline = true, -- Enabling this option, will hide inactive statuslines and replace them with a thin border instead.
--     styles = {
--         floats = 'transparent',
--         sidebars = 'transparent'
--     },
--     sidebars = { 'help', 'packer' },
-- })
-- vim.cmd [[colorscheme tokyonight]]

require('catppuccin').setup({
    flavour = 'mocha', -- latte, frappe, macchiato, mocha
    background = { -- :h background
        light = 'latte',
        dark = 'mocha',
    },
    transparent_background = true,
    show_end_of_buffer = false, -- show the '~' characters after the end of buffers
    term_colors = false,
    dim_inactive = {
        enabled = false,
        shade = 'dark',
        percentage = 0.15,
    },
    no_italic = false, -- Force no italic
    no_bold = false, -- Force no bold
    styles = {
        comments = { 'italic' },
        conditionals = { 'italic' },
        loops = {},
        functions = {},
        keywords = {},
        strings = {},
        variables = {},
        numbers = {},
        booleans = {},
        properties = {},
        types = {},
        operators = {},
    },
    color_overrides = {},
    custom_highlights = {},
    integrations = {
        alpha = true,
        fidget = true,
        harpoon = true,
        indent_blankline = {
            enabled = true,
            colored_indent_levels = false,
        },
        lsp_saga = true,
        mason = true,
        cmp = true,
        dap = {
            enabled = true,
            enable_ui = true, -- enable nvim-dap-ui
        },
        gitsigns = true,
        nvimtree = true,
        telescope = true,
        -- For more plugins integrations please scroll down (https://github.com/catppuccin/nvim#integrations)
    },
})
vim.cmd.colorscheme 'catppuccin'

-- vim.opt.background = 'dark' -- set this to dark or light
-- vim.cmd('colorscheme oxocarbon')

-- require('kanagawa').setup({
--     transparent = true,        -- do not set background color
--     dimInactive = false,        -- dim inactive window `:h hl-NormalNC`
--     globalStatus = true,       -- adjust window separators highlight for laststatus=3
--     undercurl = true,            -- enable undercurls
--     commentStyle = { italic = true },
--     keywordStyle = { italic = true},
--     statementStyle = { bold = true },
--     background = {
--         dark = 'dragon'
--     },
--     colors = {
--         theme = {
--             all = {
--                 ui = {
--                     bg_gutter = 'none'
--                 }
--             }
--         }
--     },
--     overrides = function(colors)
--         local theme = colors.theme
--         return {
--             NormalFloat = { bg = 'none' },
--             FloatBorder = { bg = 'none' },
--             -- Save an hlgroup with dark background and dimmed foreground
--             -- so that you can use it where your still want darker windows.
--             -- E.g.: autocmd TermOpen * setlocal winhighlight=Normal:NormalDark
--             NormalDark = { fg = theme.ui.fg_dim, bg = theme.ui.bg_m3 },
--             -- Popular plugins that open floats will link to NormalFloat by default;
--             -- set their background accordingly if you wish to keep them dark and borderless
--             LazyNormal = { bg = theme.ui.bg_m3, fg = theme.ui.fg_dim },
--             MasonNormal = { bg = theme.ui.bg_m3, fg = theme.ui.fg_dim },
--             -- Modern Telescope UI
--             -- TelescopeTitle = { fg = theme.ui.special, bold = true },
--             -- TelescopePromptNormal = { bg = theme.ui.bg_p1 },
--             -- TelescopePromptBorder = { fg = theme.ui.bg_p1, bg = theme.ui.bg_p1 },
--             -- TelescopeResultsNormal = { fg = theme.ui.fg_dim, bg = theme.ui.bg_m1 },
--             -- TelescopeResultsBorder = { fg = theme.ui.bg_m1, bg = theme.ui.bg_m1 },
--             -- TelescopePreviewNormal = { bg = theme.ui.bg_dim },
--             -- TelescopePreviewBorder = { bg = theme.ui.bg_dim, fg = theme.ui.bg_dim },
--             -- Dark completion (pop up) menu
--             Pmenu = { fg = theme.ui.shade0, bg = theme.ui.bg_p1 },
--             PmenuSel = { fg = 'NONE', bg = theme.ui.bg_p2 },
--             PmenuSbar = { bg = theme.ui.bg_m1 },
--             PmenuThumb = { bg = theme.ui.bg_p2 },
--         }
--     end,
-- })
-- require('kanagawa').load('dragon')

