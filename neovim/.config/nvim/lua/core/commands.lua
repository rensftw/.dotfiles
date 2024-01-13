-- Write all changes to modified buffers,
-- close all buffers except the active one,
-- and return focus to the same spot it was initially
vim.api.nvim_create_user_command('BufOnly', 'wa | %bdelete | edit # | bdelete # | normal `"', {})

-- Apply macro recorded in @a register to quickfix list items
-- exclamation mark in `norm!` is to ensure no custom mappings of abbreviations interfere
vim.api.nvim_create_user_command('ApplyMacroToQuickfix', 'cdo execute "norm! @a" | update', {})

-- Auto-resize splits when Vim gets resized.
vim.api.nvim_command [[autocmd VimResized * wincmd =]]

-- Update a buffer's contents on focus if it changed outside of Vim.
vim.api.nvim_command [[autocmd FocusGained,BufEnter * :checktime]]

-- Unset paste on InsertLeave.
vim.api.nvim_command [[autocmd InsertLeave * silent! set nopaste]]

-- Make sure all types of requirements.txt files get syntax highlighting.
vim.api.nvim_command [[autocmd BufNewFile,BufRead requirements*.txt set ft=python]]

-- Make sure .aliases, .bash_aliases and similar files get syntax highlighting.
vim.api.nvim_command [[autocmd BufNewFile,BufRead .*aliases* set ft=sh]]

-- Ensure tabs don't get converted to spaces in Makefiles.
vim.api.nvim_command [[autocmd FileType make setlocal noexpandtab]]

