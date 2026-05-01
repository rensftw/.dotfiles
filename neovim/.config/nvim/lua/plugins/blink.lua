return {
    'saghen/blink.cmp',
    version = '1.*', -- stay on stable v1; v2 is in active development
    event = 'InsertEnter',
    dependencies = {
        'L3MON4D3/LuaSnip',
        'folke/lazydev.nvim',
    },
    config = function()
        require('blink.cmp').setup({
            -- Custom keymap (preset = 'none' means "no defaults, I define everything").
            -- 'fallback' after each action lets the insert-mode mapping pass through
            -- to whatever the keybinding would do outside the completion menu.
            keymap = {
                preset     = 'none',
                ['<C-j>']  = { 'select_next', 'fallback' },
                ['<C-k>']  = { 'select_prev', 'fallback' },
                ['<C-y>']  = { 'accept', 'fallback' },
                ['<C-CR>'] = { 'accept', 'fallback' },
                ['<C-u>']  = { 'scroll_documentation_up', 'fallback' },
                ['<C-d>']  = { 'scroll_documentation_down', 'fallback' },
                ['<C-a>']  = { 'show', 'fallback' },
                ['<C-c>']  = { 'cancel', 'fallback' },
                ['<C-l>']  = { 'snippet_forward', 'fallback' },
                ['<C-h>']  = { 'snippet_backward', 'fallback' },
            },

            -- LuaSnip remains the snippet engine so your custom snippets in
            -- lua/snippets/ keep working unchanged.
            snippets = { preset = 'luasnip' },

            sources = {
                default = { 'lsp', 'path', 'snippets', 'buffer', 'lazydev' },
                -- CodeCompanion's blink provider self-gates by filetype, but
                -- scoping it via per_filetype is cleaner — blink.cmp doesn't
                -- even try the source outside chat buffers.
                per_filetype = {
                    codecompanion = { 'codecompanion', 'lsp', 'path', 'snippets', 'buffer' },
                },
                providers = {
                    -- Source names become the small tag shown next to each
                    -- completion item in the menu.
                    lsp      = { name = '󱙺 ' },
                    path     = { name = ' ' },
                    snippets = { name = ' ' },
                    buffer   = { name = '󰅍 ' },
                    lazydev  = {
                        name         = ' ',
                        module       = 'lazydev.integrations.blink',
                        score_offset = 100, -- outrank regular LSP for Nvim API completions
                    },
                    codecompanion = {
                        name   = ' ',
                        module = 'codecompanion.providers.completion.blink',
                    },
                },
            },

            completion = {
                menu = {
                    border = 'rounded',
                    draw = {
                        columns = {
                            { 'label',      'label_description', gap = 1 },
                            { 'kind_icon',  'kind' },
                            { 'source_name' },
                        },
                    },
                },
                documentation = {
                    auto_show = true,
                    window = { border = 'rounded' },
                },
            },

            cmdline = {
                enabled    = true,
                keymap     = {
                    preset     = 'cmdline',
                    ['<C-a>']  = { 'show', 'fallback' },
                    ['<C-j>']  = { 'select_next', 'fallback' },
                    ['<C-k>']  = { 'select_prev', 'fallback' },
                    ['<C-y>']  = { 'accept', 'fallback' },
                    ['<C-CR>'] = { 'accept', 'fallback' },
                },
                completion = {
                    menu = {
                        auto_show = false,
                        -- Strip the kind/source columns for cmdline only (to reduce noise)
                        draw = {
                            columns = {
                                { 'label', 'label_description', gap = 1 },
                            },
                        },
                    },
                },
                sources    = { 'path', 'cmdline' },
            },

            appearance = {
                -- Nerd-font kind icons.
                kind_icons = {
                    Text          = ' ',
                    Method        = ' ',
                    Function      = '󰊕 ',
                    Constructor   = ' ',
                    Field         = ' ',
                    Variable      = '󰫧 ',
                    Class         = ' ',
                    Interface     = ' ',
                    Module        = ' ',
                    Property      = ' ',
                    Unit          = ' ',
                    Value         = ' ',
                    Enum          = ' ',
                    Keyword       = ' ',
                    Snippet       = '󰆏 ',
                    Color         = ' ',
                    File          = ' ',
                    Reference     = '󱈤 ',
                    Folder        = ' ',
                    EnumMember    = ' ',
                    Constant      = ' ',
                    Struct        = ' ',
                    Event         = ' ',
                    Operator      = ' ',
                    TypeParameter = ' ',
                },
            },
        })
    end,
}
