return {
    'danymat/neogen',
    lazy = true,
    event = 'VeryLazy',
    dependencies = {
        'nvim-treesitter/nvim-treesitter',
        'L3MON4D3/LuaSnip',
    },
    cmd = { 'Neogen' },
    keys = {
        { mode = { 'n' }, '<leader>jd', function() require('neogen').generate({}) end },
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
