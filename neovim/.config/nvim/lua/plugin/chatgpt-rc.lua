require('chatgpt').setup({
    chat = {
        question_sign = '',
        answer_sign = '❯',
        keymaps = {
            close = { '<C-c>', 'q' },
            yank_last = '<C-y>',
            yank_last_code = '<C-k>',
            scroll_up = '<C-u>',
            scroll_down = '<C-d>',
            toggle_settings = '<C-o>',
            new_session = '<C-n>',
            cycle_windows = '<Tab>',
            select_session = { '<CR>', '<Space>' },
            rename_session = { 'cw', 'r' },
            delete_session = 'dd',
        },
    },
})
