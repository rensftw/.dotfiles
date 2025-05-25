return {
    'MeanderingProgrammer/render-markdown.nvim',
    enabled = true,
    dependencies = {
        'nvim-treesitter/nvim-treesitter',
        'nvim-tree/nvim-web-devicons',
    },
    ft = { 'codecompanion' },
    config = function ()
        require('render-markdown').setup({
            heading = {
                enabled = true,
                sign = false,
                icons = { '', '', '', '', '', '' },
            },
            code = {
                enabled = false,
                sign = true,
                border = 'thick',
                style = 'language',
                language_icon = true,
                language_name = true,
            },
            overrides = {
                filetype = {
                    codecompanion = {
                        render_modes = { 'n', 'c', 'v' },
                    },
                },
            }
        })
    end,
}
