local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

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

-- Briefly highlighting yank selection
local yank_group = augroup('HighlightYank', {})
autocmd('TextYankPost', {
    group = yank_group,
    pattern = '*',
    callback = function()
        vim.highlight.on_yank({
            higroup = 'IncSearch',
            timeout = 100,
        })
    end,
})
