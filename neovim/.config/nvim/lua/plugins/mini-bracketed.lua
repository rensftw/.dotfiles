return {
    'nvim-mini/mini.bracketed',
    lazy = true,
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
        -- Defaults bind ]X / [X for 14 targets: buffer, comment, conflict,
        -- diagnostic, file, indent, jump, location, oldfile, quickfix,
        -- treesitter, undo, window, yank. Capital letters jump to first/last.
        --
        -- Customised suffixes (`suffix = ''` skips a target's keymaps):
        --   `file`       → '' : mini.ai owns ]f / [f (see lua/plugins/mini-ai.lua)
        --   `treesitter` → '' : core/keymaps.lua owns ]t / [t for tab navigation
        --   `comment`    → '' : frees ]c / [c (was comment-block navigation)
        --   `conflict`   → 'c': ]c / [c jump between git merge-conflict markers
        --                       (<<<<<<<, =======, >>>>>>>); ]C / [C → last / first
        require('mini.bracketed').setup({
            file = { suffix = '' },
            treesitter = { suffix = '' },
            comment = { suffix = '' },
            conflict = { suffix = 'c' },
        })
    end,
}
