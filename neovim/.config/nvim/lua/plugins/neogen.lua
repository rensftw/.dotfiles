return {
    'danymat/neogen',
    dependencies = {
        'nvim-treesitter/nvim-treesitter',
        'L3MON4D3/LuaSnip',
    },
    keys = {
        { mode = { 'n' }, '<leader>jd', function() require('neogen').generate() end },
    },
    cmd = {
        'Neogen'
    },
    config = function()
        require('neogen').setup({
            snippet_engine = 'luasnip',
            languages = {
                typescript = {
                    template = {
                        annotation_convention = 'jsdoc',
                    },
                },
            },
        })
    end
}
