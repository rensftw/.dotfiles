return {
    'nvim-mini/mini.bracketed',
    lazy = true,
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
        -- Defaults bind ]X / [X for 14 targets: buffer, comment, conflict,
        -- diagnostic, file, indent, jump, location, oldfile, quickfix,
        -- treesitter, undo, window, yank. Capital letters jump to first/last.
        --
        -- Disable targets whose suffix is owned elsewhere:
        --   `file`       → mini.ai owns ]f / [f (see lua/plugins/mini-ai.lua)
        --   `treesitter` → core/keymaps.lua owns ]t / [t for tab navigation
        -- Setting `suffix = ''` skips keymap registration for that target only.
        require('mini.bracketed').setup({
            file = { suffix = '' },
            treesitter = { suffix = '' },
        })
    end,
}
