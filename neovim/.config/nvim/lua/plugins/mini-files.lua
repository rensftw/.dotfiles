return {
    'echasnovski/mini.files',
    keys = {
        { mode = { 'n' }, '<leader>e', ':lua MiniFiles.open(vim.api.nvim_buf_get_name(0))<CR>', desc = "Open filesystem in Miller view" }
    },
    config = function()
        require('mini.files').setup()
    end,
}
