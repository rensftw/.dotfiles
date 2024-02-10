local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Briefly highlighting yank selection
autocmd('TextYankPost', {
    group = augroup('HighlightYank', {}),
    pattern = '*',
    callback = function()
        vim.highlight.on_yank({
            higroup = 'IncSearch',
            timeout = 100,
        })
    end,
})

-- Auto create dir when saving a file, in case some intermediate directory does not exist
autocmd({ 'BufWritePre' }, {
    group = augroup('auto_create_dir', {}),
    callback = function(event)
        if event.match:match('^%w%w+://') then
            return
        end
        local file = vim.loop.fs_realpath(event.match) or event.match
        vim.fn.mkdir(vim.fn.fnamemodify(file, ':p:h'), 'p')
    end,
})

-- Auto-resize splits when Vim gets resized.
autocmd({ 'VimResized' }, {
    pattern = '*',
    group = augroup('auto_resize_splits', {}),
    callback = function()
        vim.api.nvim_command('wincmd =')
    end,
})

-- Update a buffer's contents on focus if it changed outside of Vim.
autocmd({ 'FocusGained', 'BufEnter' }, {
    pattern = '*',
    group = augroup('update_buffer_contents_if_changed_outside_neovim', {}),
    callback = function()
        vim.api.nvim_command('checktime')
    end,
})

-- Unset paste on InsertLeave.
autocmd({ 'InsertLeave' }, {
    pattern = '*',
    group = augroup('unset_paste_on_insertleave', {}),
    callback = function()
        vim.api.nvim_command('silent! set nopaste')
    end,
})

-- Make sure all types of requirements.txt files get syntax highlighting.
autocmd({ 'BufNewFile', 'BufRead' }, {
    pattern = 'requirements*.txt',
    group = augroup('enable_syntax_highlighting_of_requirements_txt', {}),
    callback = function()
        vim.api.nvim_command('set ft=python')
    end,
})

-- Make sure .aliases, .bash_aliases and similar files get syntax highlighting.
autocmd({ 'BufNewFile', 'BufRead' }, {
    pattern = '*aliases*',
    group = augroup('enable_syntax_highlighting_of_aliases', {}),
    callback = function()
        vim.api.nvim_command('set ft=sh')
    end,
})

-- Ensure tabs don't get converted to spaces in Makefiles.
autocmd('FileType', {
    pattern = 'make',
    group = augroup('preserve_tabs_in_makefile', {}),
    callback = function()
        vim.opt_local.expandtab = false
    end,
})

-- Close some filetypes with <q>
autocmd('FileType', {
    group = augroup('close_with_q', {}),
    pattern = {
        'PlenaryTestPopup',
        'fugitive',
        'fugitiveblame',
        'help',
        'lspinfo',
        'man',
        'notify',
        'qf',
        'nvimtree',
        'git',
        'spectre_panel',
        'startuptime',
        'tsplayground',
        'neotest-output',
        'checkhealth',
        'neotest-summary',
        'neotest-output-panel',
    },
    callback = function(event)
        vim.bo[event.buf].buflisted = false
        vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = event.buf, silent = true })
    end,
})

-- Make fugitive toggle-able with <leader>gg
autocmd('FileType', {
    group = augroup('make_fugitive_toggleable', {}),
    pattern = { 'fugitive' },
    callback = function(event)
        vim.bo[event.buf].buflisted = false
        vim.keymap.set('n', '<leader>gg', '<cmd>close<cr>', { buffer = event.buf, silent = true })
    end,
})

