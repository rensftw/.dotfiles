return {
    'MeanderingProgrammer/render-markdown.nvim',
    enabled = true,
    dependencies = {
        'nvim-treesitter/nvim-treesitter',
        'nvim-tree/nvim-web-devicons',
    },
    ft = { 'markdown', 'codecompanion' },
    config = function ()

        require('render-markdown').setup({
            render_modes = true,
            heading = {
                enabled = true,
                sign = false,
            },
            code = {
                enabled = true,
                sign = true,
                border = 'thick',
                style = 'language',
            },
            html = {
                enabled = true,
                tag = {
                    buf         = { icon = ' ',  highlight = 'CodeCompanionChatVariable' },
                    file        = { icon = ' ',  highlight = 'CodeCompanionChatVariable' },
                    help        = { icon = '󰘥 ',  highlight = 'CodeCompanionChatVariable' },
                    image       = { icon = ' ',  highlight = 'CodeCompanionChatVariable' },
                    symbols     = { icon = ' ',  highlight = 'CodeCompanionChatVariable' },
                    url         = { icon = '󰖟 ',  highlight = 'CodeCompanionChatVariable' },
                    var         = { icon = ' ',  highlight = 'CodeCompanionChatVariable' },
                    tool        = { icon = ' ',  highlight = 'CodeCompanionChatTool' },
                    prompt      = { icon = ' ',  highlight = 'CodeCompanionChatTool' },
                    group       = { icon = ' ',  highlight = 'CodeCompanionChatToolGroup' },
                },
            },
        })
    end,
}
