return {
    'nvim-mini/mini.icons',
    lazy = true,
    config = function()
        -- mini.icons categorises by `extension` / `file` / `filetype` and
        -- treats them as **separate** lookup tables — `extension.sh` is NOT
        -- consulted when something asks for `filetype.sh`. The statusline
        -- queries by filetype (`MiniIcons.get('filetype', vim.bo.filetype)`),
        -- so anything we want the statusline to colour must live under
        -- `filetype`. The `extension` / `file` entries cover other consumers
        -- like alpha-nvim and fzf-lua's file-type display.
        --
        -- Highlight groups use mini.icons' standard palette (MiniIconsAzure
        -- / Blue / Cyan / Green / Grey / Orange / Purple / Red / Yellow),
        -- which the catppuccin and tokyonight integrations both colourise.
        require('mini.icons').setup({
            filetype = {
                javascript = { hl = 'MiniIconsYellow' },
                typescript = { hl = 'MiniIconsBlue' },
                html       = { hl = 'MiniIconsOrange' },
                css        = { hl = 'MiniIconsBlue' },
                sh         = { hl = 'MiniIconsGreen' },
                bash       = { hl = 'MiniIconsGreen' },
                zsh        = { hl = 'MiniIconsGreen' },
                gitcommit  = { glyph = '', hl = 'MiniIconsOrange' },
                gitignore  = { glyph = '󰊢', hl = 'MiniIconsOrange' },
            },
            file = {
                ['.gitignore']     = { glyph = '󰊢', hl = 'MiniIconsOrange' },
                ['.gitattributes'] = { glyph = '󰊢', hl = 'MiniIconsOrange' },
                ['.gitmodules']    = { glyph = '󰊢', hl = 'MiniIconsOrange' },
                ['COMMIT_EDITMSG'] = { glyph = '󰵅', hl = 'MiniIconsOrange' },
            },
        })

        -- Expose mini.icons under the `nvim-web-devicons` API so plugins
        -- that hard-require devicons (e.g. diffview.nvim) get our icons
        -- instead of complaining. Must run after setup().
        MiniIcons.mock_nvim_web_devicons()
    end,
}
