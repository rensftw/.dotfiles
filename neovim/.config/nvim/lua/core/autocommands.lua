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

-- NOTE: Order is important!!!
-- reset_line_wrapping must be defined before allow_line_wrapping
-- We need this to ensure filetypes that contain code do not have wrap enabled
autocmd('FileType', {
    group = augroup('reset_line_wrapping', {}),
    pattern = '*',
    callback = function()
        vim.wo.wrap = false
        vim.wo.linebreak = false
        vim.wo.breakindent = false
        vim.wo.showbreak = ''
    end,
})

-- Improve writing experience
-- Enable line wrapping for text filetypes
autocmd('FileType', {
    group = augroup('allow_line_wrapping', {}),
    pattern = {
        'Markdown',
        'Text',
        'Asciidoc',
        'Pandoc',
        'Tex',
        'Rtf',
        'Gitcommit'
    },
    callback = function()
        vim.wo.wrap = true -- Enable line wrapping for long lines
        vim.wo.linebreak = true -- Do not split words for linebreak
        vim.wo.breakindent = true -- Prevent word splitting
        vim.wo.showbreak = '⋮ ' -- Symbol to indicate wrapped line

        -- NOTE: Uncomment to automatically insert a new line at col 80 as you type
        -- vim.o.textwidth = 80

        -- Fun fact:
        -- `Gitcommit` filetypes default to 72 lines of textwidth (and not 80 which is the default)
    end,
})
