return {
    'folke/todo-comments.nvim',
    event = 'VeryLazy',
    keys = {
        { ']n', mode = 'n', desc = 'Next TODO/FIX/NOTE comment' },
        { '[n', mode = 'n', desc = 'Previous TODO/FIX/NOTE comment' },
    },
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
        require('todo-comments').setup({
            signs = false,
            search = {
                command = 'rg',
                args = {
                    '--hidden',
                    '--color=never',
                    '--no-heading',
                    '--with-filename',
                    '--line-number',
                    '--column',
                },
            },
        })

        local keywords = {
            'FIX',
            'TODO',
            'HACK',
            'WARN',
            'PERF',
            'NOTE',
            'TEST',
        }

        -- ]n / [n (was ]c / [c, which now navigates git conflicts).
        vim.keymap.set('n', ']n', function()
            require('todo-comments').jump_next({ keywords = keywords })
        end, { desc = 'Next TODO/FIX/NOTE comment' })

        vim.keymap.set('n', '[n', function()
            require('todo-comments').jump_prev({ keywords = keywords })
        end, { desc = 'Previous TODO/FIX/NOTE comment' })
    end
}
