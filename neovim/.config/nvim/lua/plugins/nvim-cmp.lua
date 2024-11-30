return {
    'hrsh7th/nvim-cmp',
    event = 'InsertEnter',
    dependencies = {
        -- completion sources:
        'hrsh7th/cmp-nvim-lsp',
        'hrsh7th/cmp-nvim-lua',
        'hrsh7th/cmp-buffer',
        'hrsh7th/cmp-path',
        'hrsh7th/cmp-cmdline',
        -- Snippets
        'L3MON4D3/LuaSnip',
        'saadparwaiz1/cmp_luasnip',
    },
    config = function()
        local cmp = require('cmp')
        local luasnip = require('luasnip')

        local confirm = cmp.mapping.confirm({
            behavior = cmp.ConfirmBehavior.Insert,
            select = true,
        })

        cmp.setup({
            snippet = {
                expand = function(args)
                    luasnip.lsp_expand(args.body)
                end,
            },
            mapping = {
                ['<C-l>'] = cmp.mapping(function(fallback)
                    if luasnip.expand_or_jumpable() then
                        luasnip.expand_or_jump()
                    else
                        fallback()
                    end
                end, { 'i', 's' }),
                ['<C-h>'] = cmp.mapping(function(fallback)
                    if luasnip.jumpable(-1) then
                        luasnip.jump(-1)
                    else
                        fallback()
                    end
                end, { 'i', 's' }),
                ['<C-j>'] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.select_next_item({ behavior = cmp.SelectBehavior.Insert })
                    else
                        fallback()
                    end
                end, { 'i', 's' }),
                ['<C-k>'] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.select_prev_item({ behavior = cmp.SelectBehavior.Insert })
                    else
                        fallback()
                    end
                end, { 'i', 's' }),
                ['<C-y>'] = cmp.mapping(confirm),
                ['<C-CR>'] = cmp.mapping(confirm),
                ['<C-u>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i', 'c' }),
                ['<C-d>'] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i', 'c' }),
                ['<C-a>'] = cmp.mapping(cmp.mapping.complete(), { 'i', 'c' }),
                ['<C-c>'] = cmp.mapping(cmp.mapping.close(), { 'i', 'c' }),
            },
            window = {
                completion = cmp.config.window.bordered(),
                documentation = cmp.config.window.bordered(),
            },
            sources = cmp.config.sources({
                { name = 'nvim_lsp' },
                {
                    name = 'lazydev',
                    group_index = 0, -- set group index to 0 to skip loading LuaLS completions
                },
                { name = 'luasnip' },
                { name = 'buffer' },
                { name = 'path' },
            }),
            formatting = {
                fields = { 'abbr', 'kind', 'menu' },
                expandable_indicator = true,
                format = function(entry, vim_item)
                    vim_item.menu = ({
                        nvim_lsp = '󱙺',
                        nvim_lua = '',
                        luasnip  = '',
                        buffer   = '󰅍',
                        path     = '',
                    })[entry.source.name]
                    vim_item.kind = ({
                        Text          = '',
                        Method        = '',
                        Function      = '󰊕',
                        Constructor   = '',
                        Field         = '',
                        Variable      = '󰫧',
                        Class         = '',
                        Interface     = '',
                        Module        = '',
                        Property      = '',
                        Unit          = '',
                        Value         = '',
                        Enum          = '',
                        Keyword       = '',
                        Snippet       = '󰆏',
                        Color         = '',
                        File          = '',
                        Reference     = '󱈤',
                        Folder        = '',
                        EnumMember    = '',
                        Constant      = '',
                        Struct        = '',
                        Event         = '',
                        Operator      = '',
                        TypeParameter = '',
                    })[vim_item.kind]
                    return vim_item
                end
            },
        })

        -- Use cmdline & path source for ':'.
        cmp.setup.cmdline(':', {
            completion = { autocomplete = false },
            sources = cmp.config.sources({
                { name = 'path' }
            }, {
                { name = 'cmdline' }
            })
        })


        -- Supply completions in DAP buffers
        cmp.setup.filetype({ 'dap-repl', 'dapui_watches' }, {
            sources = {
                { name = 'dap' },
            },
        })
    end
}
