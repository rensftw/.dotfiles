return {
    'nvim-mini/mini.bracketed',
    lazy = true,
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
        -- Defaults bind ]X / [X for 14 targets: buffer, comment, conflict,
        -- diagnostic, file, indent, jump, location, oldfile, quickfix,
        -- treesitter, undo, window, yank. Capital letters jump to first/last.
        --
        -- Disable the `file` target — mini.ai owns ]f / [f for function
        -- navigation (see lua/plugins/mini-ai.lua). Setting `suffix = ''`
        -- skips the keymap registration for this target only.
        require('mini.bracketed').setup({
            file = { suffix = '' },
        })
    end,
}
