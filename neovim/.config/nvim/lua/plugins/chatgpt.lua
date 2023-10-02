return {
    'jackMort/ChatGPT.nvim',
    cmd = {
        'ChatGPT',
        'ChatGPTActAs',
        'ChatGPTEditWithInstructions',
        'ChatGPTRun'
    },
    keys = {
        { mode = { 'n' }, '<leader>cg', ':ChatGPT<CR>', },
        { mode = { 'n' }, '<leader>cp', ':ChatGPTActAs<CR>', },
        { mode = { 'v' }, '<leader>ce', ":'<,'>ChatGPTEditWithInstructions<CR>", },
        { mode = { 'v' }, '<leader>cx', ":'<,'>ChatGPTRun explain_code<CR>", },
    },
    dependencies = { 'MunifTanjim/nui.nvim', },
    config = function()
        require('chatgpt').setup({
            popup_input = {
                prompt = '  ',
                submit = '<C-Enter>',
                submit_n = '<C-Enter>',
            },
            chat = {
                question_sign = '',
                answer_sign = '󱙺',
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
                    stop_generating = '<C-x>',
                },
            },
            edit_with_instructions = {
                diff = false,
                keymaps = {
                    close = '<C-c>',
                    accept = '<C-y>',
                    toggle_diff = '<C-d>',
                    toggle_settings = '<C-o>',
                    cycle_windows = '<Tab>',
                    use_output_as_input = '<C-u>',
                },
            },
            system_window = {
                border = {
                    text = {
                        top = ' 󱓥 SYSTEM ',
                    },
                },
            },
            openai_params = {
                model = 'gpt-4',
            },
        })
    end
}
