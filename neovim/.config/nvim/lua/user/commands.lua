-- Write all changes to modified buffers,
-- close all buffers except the active one,
-- and return focus to the same spot it was initially
vim.api.nvim_create_user_command('BufOnly', 'wa | %bdelete | edit # | bdelete # | normal `"', {})

-- Git show a commit using difftool
vim.api.nvim_create_user_command('GitShow', 'Git difftool -y <args>~ <args>', {})
