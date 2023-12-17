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
