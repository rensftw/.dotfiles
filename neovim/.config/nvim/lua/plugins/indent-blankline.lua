return {
    'lukas-reineke/indent-blankline.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
        require('indent_blankline').setup {
            indent_blankline_buftype_exclude = {
                'terminal',
                'nofile',
                'quickfix',
                'prompt',
            },
            indent_blankline_filetype_exclude = {
                'checkhealth',
                'lspinfo',
                'help',
                'man',
                'packer',
                'mason',
                'alpha',
            },
            space_char_blankline = ' ',
            show_current_context = true,
            show_current_context_start = true,
            use_treesitter = true,
        }
    end
}
