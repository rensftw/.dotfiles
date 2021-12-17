local cmp = require'cmp'

cmp.setup({
    snippet = {
        expand = function(args)
            vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
        end,
    },
    mapping = {
        ['<S-up>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i', 'c' }),
        ['<S-down>'] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i', 'c' }),
        ['<C-y>'] = cmp.config.disable,
        ['<C-e>'] = cmp.mapping({
            i = cmp.mapping.abort(),
            c = cmp.mapping.close(),
        }),
        ['<CR>'] = cmp.mapping.confirm({ select = true }),
    },
    sources = cmp.config.sources({
        { name = 'nvim_lsp' },
        { name = 'ultisnips' },
        { name = 'buffer' },
    }),
    formatting = {
        format = function(entry, vim_item)
            vim_item.menu = ({
                nvim_lsp = '',
                buffer   = '',
            })[entry.source.name]
            vim_item.kind = ({
                Text          = '',
                Method        = '',
                Function      = '',
                Constructor   = '',
                Field         = '',
                Variable      = '',
                Class         = '',
                Interface     = 'ﰮ',
                Module        = '',
                Property      = '',
                Unit          = '',
                Value         = '',
                Enum          = '',
                Keyword       = '',
                Snippet       = '﬌',
                Color         = '',
                File          = '',
                Reference     = '',
                Folder        = '',
                EnumMember    = '',
                Constant      = '',
                Struct        = '',
                Event         = '',
                Operator      = 'ﬦ',
                TypeParameter = '',
            })[vim_item.kind]
            return vim_item
        end
    },
})
