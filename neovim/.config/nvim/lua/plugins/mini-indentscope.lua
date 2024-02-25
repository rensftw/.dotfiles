return {
    'echasnovski/mini.indentscope',
    version = false,
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
        require('mini.indentscope').setup({
            draw = {
                animation = require('mini.indentscope').gen_animation.none(),
            },
            symbol = '▏',
        })

        local augroup = vim.api.nvim_create_augroup
        local autocmd = vim.api.nvim_create_autocmd

        autocmd('FileType', {
            group = augroup('exclude_filetypes_for_mini_indentscope', {}),
            pattern = {
                'checkhealth',
                'lspinfo',
                'help',
                'man',
                'lazy',
                'mason',
                'alpha',
            },
            callback = function(event)
                vim.b.miniindentscope_disable = true
            end,
        })
    end,
}
