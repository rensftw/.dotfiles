return {
    'catppuccin/nvim',
    enabled = false,
    -- Load main theme before all other plugins
    lazy = false,
    priority = 1000,
    name = 'catppuccin',
    config = function()
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
                alpha              = true,
                blink_cmp          = true,
                dap                = { enabled = true, enable_ui = true },
                diffview           = true,
                fidget             = true,
                gitsigns           = true,
                harpoon            = true,
                mason              = true,
                mini               = { enabled = true, indentscope_color = '' },
                native_lsp         = { enabled = true },
                render_markdown    = true,
                todo_comments      = true,
                treesitter         = true,
                treesitter_context = true,
                -- For more plugins integrations please scroll down (https://github.com/catppuccin/nvim#integrations)
            },
        })

        vim.cmd [[colorscheme catppuccin]]
    end
}
