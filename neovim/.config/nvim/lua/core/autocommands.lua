local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Briefly highlighting yank selection
autocmd('TextYankPost', {
    group = augroup('HighlightYank', {}),
    pattern = '*',
    callback = function()
        vim.hl.on_yank({
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
        local file = vim.uv.fs_realpath(event.match) or event.match
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
        -- :checktime is disallowed inside the command-line window (q:, q/, q?) — E11.
        if vim.fn.getcmdwintype() ~= '' then return end
        vim.cmd('checktime')
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
        'git',
        'help',
        'lspinfo',
        'man',
        'notify',
        'qf',
        'checkhealth',
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

-- Restore fugitive status windows after a session is loaded.
-- vim-obsession records the :Git status buffer's fugitive:// name in Session.vim,
-- but fugitive is lazy-loaded, so when `nvim -S` sources `edit fugitive://...`
-- during startup its BufReadCmd handler isn't registered yet and the window comes
-- up as an empty buffer. Once the session has fully loaded, force fugitive to load
-- and re-read any windowed fugitive:// buffers so the status content regenerates.
autocmd('SessionLoadPost', {
    group = augroup('restore_fugitive_on_session_load', {}),
    callback = function()
        local fugitive_wins = {}
        for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
            for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
                local buf = vim.api.nvim_win_get_buf(win)
                if vim.api.nvim_buf_get_name(buf):match('^fugitive://') then
                    table.insert(fugitive_wins, win)
                end
            end
        end

        if #fugitive_wins == 0 then return end

        -- Ensure fugitive's BufReadCmd handlers exist before reloading.
        pcall(function() require('lazy').load({ plugins = { 'vim-fugitive' } }) end)

        -- Defer the reload out of this autocmd's context. A :edit run *inside* the
        -- SessionLoadPost callback does NOT trigger fugitive's BufReadCmd, because
        -- autocommands don't nest by default — so the status would never render.
        -- Scheduling runs it on the next loop tick (after the session source returns),
        -- where BufReadCmd fires normally and regenerates the status.
        vim.schedule(function()
            for _, win in ipairs(fugitive_wins) do
                if vim.api.nvim_win_is_valid(win) then
                    vim.api.nvim_win_call(win, function()
                        pcall(vim.cmd, 'edit!')
                    end)
                end
            end
        end)
    end,
})
