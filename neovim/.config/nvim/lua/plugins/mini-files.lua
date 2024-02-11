return {
    'echasnovski/mini.files',
    lazy = true,
    event = 'VeryLazy',
    keys = {
        { mode = { 'n' }, '<leader>e', ':lua MiniFiles.open(vim.api.nvim_buf_get_name(0))<CR>', desc = "Open filesystem in Miller view" }
    },
    config = function()
        require('mini.files').setup({
            mappings = {
                go_in_plus = '<CR>',
            },

        })
    end,
}
