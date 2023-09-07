return {
    'folke/tokyonight.nvim',
    -- Load main theme before all other plugins
    lazy = false,
    priority = 1000,
    config = function()
        require('tokyonight').setup({
            style = 'night',
            transparent = true,
            dim_inactive = true,
            hide_inactive_statusline = true, -- Enabling this option, will hide inactive statuslines and replace them with a thin border instead.
            styles = {
                floats = 'transparent',
                sidebars = 'transparent'
            },
            sidebars = { 'help', 'packer' },
        })

        vim.cmd [[colorscheme tokyonight]]
    end
}
