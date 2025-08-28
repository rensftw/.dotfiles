-- (mini.files) `get_target_window()` is soft deprecated . Use `get_explorer_state().target_window` instead. Sorry for the inconvenience.
return {
    'nvim-mini/mini.files',
    lazy = true,
    event = 'VeryLazy',
    keys = {
        { mode = { 'n' }, '<leader>e', ':lua MiniFiles.open(vim.api.nvim_buf_get_name(0))<CR>', desc = "Open filesystem in Miller view" }
    },
    config = function()
        require('mini.files').setup({
            mappings = {
                go_in_plus = '<CR>',
            },
        })

        local map_split = function(buf_id, lhs, direction)
            local rhs = function()
                -- Make new window and set it as target
                local new_target_window
                vim.api.nvim_win_call(MiniFiles.get_explorer_state().target_window, function()
                    vim.cmd(direction .. ' split')
                    new_target_window = vim.api.nvim_get_current_win()
                end)

                MiniFiles.set_target_window(new_target_window)
                MiniFiles.go_in({})
            end

            -- Adding `desc` will result into `show_help` entries
            local desc = 'Split ' .. direction
            vim.keymap.set('n', lhs, rhs, { buffer = buf_id, desc = desc })
        end

        vim.api.nvim_create_autocmd('User', {
            pattern = 'MiniFilesBufferCreate',
            callback = function(args)
                local buf_id = args.data.buf_id
                map_split(buf_id, '<C-x>', 'belowright horizontal')
                map_split(buf_id, '<C-v>', 'belowright vertical')
            end,
        })
    end,
}
