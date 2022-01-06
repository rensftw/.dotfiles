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
vim.api.nvim_command [[command! BufOnly execute 'wa | %bdelete | edit # | bdelete # | normal `"']]

-- Git show a commit using difftool
    -- function! GitShowHelper(commitHash)
    --     execute Git show commitHash~ commitHash
    -- endfunction

vim.api.nvim_command [[command! -nargs=1 GitShow execute 'Git difftool -y <args>~ <args>']]

