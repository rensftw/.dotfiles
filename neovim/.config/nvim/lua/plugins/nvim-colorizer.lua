return {
    'norcalli/nvim-colorizer.lua',
    lazy = true,
    event = { 'BufReadPost', 'BufNewFile' },
    config = function()
        require 'colorizer'.setup()
    end
}
