require('chatgpt').setup({
    popup_input = {
        prompt = '  ',
        submit = '<C-Enter>',
        submit_n = '<C-Enter>',
    },
    chat = {
        question_sign = '',
        answer_sign = '❯',
        keymaps = {
            close = { '<C-c>', },
            yank_last = '<C-y>',
            yank_last_code = '<C-k>',
            scroll_up = '<C-u>',
            scroll_down = '<C-d>',
            toggle_settings = '<C-o>',
            new_session = '<C-n>',
            cycle_windows = '<Tab>',
            cycle_modes = '<C-v>', -- opens ChatGPT to the right
            select_session = { '<CR>', '<Space>' },
            rename_session = { 'cw', 'r' },
            delete_session = 'dd',
            draft_message = '<C-m>',
            toggle_message_role = '<C-r>',
            toggle_system_role_open = '<C-s>',
        },
    },
    system_window = {
        border = {
            text = {
                top = ' 󱓥 ',
            },
        },
    },
})
