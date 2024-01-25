return {
    'kepano/flexoki-neovim',
    name = 'flexoki',
    -- Load main theme before all other plugins
    enabled = true,
    lazy = false,
    priority = 1000,
    config = function()
        vim.cmd('colorscheme flexoki-dark')
    end
}
