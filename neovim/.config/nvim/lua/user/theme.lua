require('tokyonight').setup({
    style = 'night',
    transparent = true,
    dim_inactive = true,
    hide_inactive_statusline = true, -- Enabling this option, will hide inactive statuslines and replace them with a thin border instead.
    styles = {
        floats = 'transparent',
        sidebars = 'transparent'
    },
    sidebars = { 'help', 'packer' },
})

vim.cmd [[colorscheme tokyonight]]

-- require('catppuccin').setup({
--     flavour = 'mocha', -- latte, frappe, macchiato, mocha
--     background = { -- :h background
--         light = 'latte',
--         dark = 'mocha',
--     },
--     transparent_background = true,
--     show_end_of_buffer = false, -- show the '~' characters after the end of buffers
--     term_colors = false,
--     dim_inactive = {
--         enabled = false,
--         shade = 'dark',
--         percentage = 0.15,
--     },
--     no_italic = false, -- Force no italic
--     no_bold = false, -- Force no bold
--     styles = {
--         comments = { 'italic' },
--         conditionals = { 'italic' },
--         loops = {},
--         functions = {},
--         keywords = {},
--         strings = {},
--         variables = {},
--         numbers = {},
--         booleans = {},
--         properties = {},
--         types = {},
--         operators = {},
--     },
--     color_overrides = {},
--     custom_highlights = {},
--     integrations = {
--         alpha = true,
--         fidget = true,
--         harpoon = true,
--         indent_blankline = {
--             enabled = true,
--             colored_indent_levels = false,
--         },
--         lsp_saga = true,
--         mason = true,
--         cmp = true,
--         dap = {
--             enabled = true,
--             enable_ui = true, -- enable nvim-dap-ui
--         },
--         gitsigns = true,
--         nvimtree = true,
--         telescope = true,
--         -- For more plugins integrations please scroll down (https://github.com/catppuccin/nvim#integrations)
--     },
-- })
-- vim.cmd.colorscheme 'catppuccin'

