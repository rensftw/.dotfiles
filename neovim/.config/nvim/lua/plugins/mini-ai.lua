return {
    'nvim-mini/mini.ai',
    lazy = true,
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
        { 'nvim-treesitter/nvim-treesitter-textobjects', branch = 'main' },
    },
    config = function()
        local mini_ai  = require('mini.ai')
        local gen_spec = mini_ai.gen_spec

        -- Treesitter-driven function/class/parameter textobjects:
        --   af/if  function (outer/inner)
        --   ac/ic  class
        --   aa/ia  parameter
        --
        -- mini.ai's defaults add smarter brackets/quotes/tags
        -- (a)/i), a"/i", at/it for HTML/JSX), function-call expression `af`,
        -- and prompted custom delimiters via a?/i?.
        mini_ai.setup({
            -- mini.ai defaults to 50 — too small for real codebases where
            -- the next function/class can easily be 100+ lines away. Bump
            -- to keep `]f`/`[f`/`vaf` working in longer files.
            n_lines = 500,

            custom_textobjects = {
                f = gen_spec.treesitter({
                    a = '@function.outer',
                    i = '@function.inner',
                }),
                c = gen_spec.treesitter({
                    a = '@class.outer',
                    i = '@class.inner',
                }),
                a = gen_spec.treesitter({
                    a = '@parameter.outer',
                    i = '@parameter.inner',
                }),
            },
        })

        -- Move keymaps via MiniAi.move_cursor:
        --   side='left'  -> start of textobject
        --   side='right' -> end of textobject
        local function move(side, ai_type, id, search)
            return function()
                mini_ai.move_cursor(side, ai_type, id, { search_method = search })
            end
        end

        local map   = vim.keymap.set
        local modes = { 'n', 'x', 'o' }

        map(modes, ']f', move('left',  'a', 'f', 'next'), { desc = 'next function start' })
        map(modes, '[f', move('left',  'a', 'f', 'prev'), { desc = 'prev function start' })
        map(modes, ']F', move('right', 'a', 'f', 'next'), { desc = 'next function end' })
        map(modes, '[F', move('right', 'a', 'f', 'prev'), { desc = 'prev function end' })
        -- Class *motions* (]c/[c, ]C/[C) are intentionally not mapped: ]c/[c now
        -- navigate git conflicts (mini.bracketed). The `ac`/`ic` class
        -- textobjects (select/operate) remain available via custom_textobjects.
    end,
}
