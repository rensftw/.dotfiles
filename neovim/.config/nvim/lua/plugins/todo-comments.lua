return {
    'folke/todo-comments.nvim',
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

        vim.keymap.set('n', ']c', function()
            require('todo-comments').jump_next({ keywords = keywords })
        end, { desc = 'Next semantic comment' })

        vim.keymap.set('n', '[c', function()
            require('todo-comments').jump_prev({ keywords = keywords })
        end, { desc = 'Previous semantic comment' })
    end
}
