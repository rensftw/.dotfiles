return function(filepath)
    local chat_bufnr = vim.api.nvim_get_current_buf()

    -- Try to go to the previous window
    vim.cmd('wincmd p')

    -- Check if we're still in the chat buffer
    if vim.api.nvim_get_current_buf() == chat_bufnr then
        -- If still in chat buffer, find another window or create split
        local wins = vim.api.nvim_list_wins()
        local target_win = nil
        for _, win in ipairs(wins) do
            local win_buf = vim.api.nvim_win_get_buf(win)
            if win_buf ~= chat_bufnr then
                target_win = win
                break
            end
        end

        if target_win then
            vim.api.nvim_set_current_win(target_win)
        else
            vim.cmd('vsplit')
        end
    end

    vim.cmd('edit ' .. vim.fn.fnameescape(filepath))
end
