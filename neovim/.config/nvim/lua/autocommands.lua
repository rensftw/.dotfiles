local command = vim.api.nvim_command
-- Auto-resize splits when Vim gets resized.
command [[autocmd VimResized * wincmd =]]

-- Update a buffer's contents on focus if it changed outside of Vim.
command [[autocmd FocusGained,BufEnter * :checktime]]

-- Unset paste on InsertLeave.
command [[autocmd InsertLeave * silent! set nopaste]]

-- Make sure all types of requirements.txt files get syntax highlighting.
command [[autocmd BufNewFile,BufRead requirements*.txt set ft=python]]

-- Make sure .aliases, .bash_aliases and similar files get syntax highlighting.
command [[autocmd BufNewFile,BufRead .*aliases* set ft=sh]]

-- Ensure tabs don't get converted to spaces in Makefiles.
command [[autocmd FileType make setlocal noexpandtab]]

-- Only show the cursor line in the active buffer.
vim.cmd [[
    augroup CursorLine
        au!
        au VimEnter,WinEnter,BufWinEnter * setlocal cursorline
        au WinLeave * setlocal nocursorline
    augroup END
]]

-- Write all changes to modified buffers,
-- close all buffers except the active one,
-- and return focus to the same spot it was initially
command [[command! BufOnly execute 'wa | %bdelete | edit # | bdelete # | normal `"']]
