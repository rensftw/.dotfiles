return {
    'folke/tokyonight.nvim',
    -- Keep the Tokyonight theme on the startup path, but make its setup
    -- deterministic and cache-friendly. The cache is keyed by style/options and
    -- avoids regenerating highlight tables on normal starts.
    lazy = false,
    priority = 1000,
    config = function()
        require('tokyonight').setup({
            style = 'night',
            transparent = true,
            dim_inactive = true,
            hide_inactive_statusline = true,
            styles = {
                floats = 'transparent',
                sidebars = 'transparent',
            },
            sidebars = { 'help', 'lazy' },
            cache = true,
            plugins = {
                -- Core, treesitter and semantic-token groups stay enabled by
                -- default; use Tokyonight's lazy.nvim plugin scan to detect
                -- installed plugins.
                all = false,
                auto = true,
            },
        })

        vim.cmd.colorscheme('tokyonight')
    end,
}
