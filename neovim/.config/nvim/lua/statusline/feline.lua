return {
    'feline-nvim/feline.nvim',
    event = 'UiEnter',
    dependencies = {
        'kyazdani42/nvim-web-devicons',
        'lewis6991/gitsigns.nvim',
        'tpope/vim-obsession',
    },
    config = function()
        local line_ok, feline = pcall(require, 'feline')
        if not line_ok then
            return
        end

        local themes = require('statusline.feline-themes')
        local statusbar = require('statusline.feline-statusbar')
        local winbar = require('statusline.feline-winbar')

        feline.setup({
            components = statusbar.components,
            theme = themes.tokyonight_colors,
            vi_mode_colors = themes.tokyonight_vi_mode_colors,
        })

        feline.winbar.setup({
            components = winbar.components,
            disable = {
                filetypes = {
                    '^NvimTree$',
                    '^packer$',
                    '^startify$',
                    '^fugitive$',
                    '^fugitiveblame$',
                    '^qf$',
                    '^help$',
                },
                buftypes = {
                    '^terminal$',
                },
                bufnames = {},
            },
        })
    end
}
