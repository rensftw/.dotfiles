-- Write all changes to modified buffers,
-- close all buffers except the active one,
-- and return focus to the same spot it was initially
vim.api.nvim_create_user_command('BufOnly', 'wa | %bdelete | edit # | bdelete # | normal `"', {})

-- Apply macro recorded in @a register to quickfix list items
-- exclamation mark in `norm!` is to ensure no custom mappings of abbreviations interfere
vim.api.nvim_create_user_command('ApplyMacroToQuickfix', 'cdo execute "norm! @a" | update', {})

