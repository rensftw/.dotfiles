return {
    'windwp/nvim-autopairs',
    lazy = true,
    event = 'InsertEnter',
    config = function()
        require('nvim-autopairs').setup {}
    end
}
