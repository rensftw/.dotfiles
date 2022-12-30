local map = vim.keymap.set
local opts = { noremap = true, silent = true }

map('n', 'Q', ':wqall<CR>', opts)
map('n', 'W', ':wall<CR>', opts)

-- Clears hlsearch after doing a search, otherwise just does normal <CR> stuff
map('n', '<CR>', function()
    return vim.v.hlsearch == 1 and ':nohl<CR>' or '<CR>'
end, { expr = true, silent = true, nowait = true })

-- Undotree
map('n', '<leader>u', '<cmd>UndotreeToggle<CR>', opts)

-- Delete all other buffers
map('n', 'B', ':BufOnly<CR>', opts)

-- Close all other tabs
map('n', 'T', ':tabonly<CR>', opts)

-- Yank to the end of line
map('n', 'Y', 'yg$', opts)

-- Yank to clipboard
map('n', '<leader>Y', '\"+yg$', opts) --to the end of line
map('n', '<leader>y', '\"+y', opts)
map('v', '<leader>y', '\"+y', opts)

-- Prevent x from overriding what's in the clipboard.
map('n', 'x', '"_x', opts)
map('n', 'X', '"_x', opts)

-- Prevent selecting and pasting from overwriting what you originally copied.
map('x', 'p', 'pgvy', opts)

-- Keep cursor at the bottom of the visual selection after you yank it.
map('v', 'y', 'ygv<Esc>', opts)

-- Stay in indent mode
map('v', '>', '>gv', opts)
map('v', '<', '<gv', opts)

-- Center scrolling
map('n', '<C-d>', '<C-d>zz', opts)
map('n', '<C-u>', '<C-u>zz', opts)

-- Center search results
map('n', 'n', 'nzz', opts)
map('n', 'N', 'Nzz', opts)
map('n', '*', '*zz', opts)
map('n', '#', '#zz', opts)
map('n', 'g*', 'g*zz', opts)
map('n', 'g#', 'g#zz', opts)

-- Center quickfix results when navigating
map('n', ']q', '<cmd>cnext<CR>zz', opts)
map('n', '[q', '<cmd>cprev<CR>zz', opts)

-- Move 1 or more lines up or down in normal and visual selection modes.
map('n', 'K', ':m .-2<CR>==', opts)
map('n', 'J', ':m .+1<CR>==', opts)
map('v', 'K', ":m '<-2<CR>gv=gv", opts)
map('v', 'J', ":m '>+1<CR>gv=gv", opts)

-- Resize splits
map('n', '+', ':resize +2<CR>', opts)
map('n', '_', ':resize -3<CR>', opts)
map('n', '=', ':vertical resize +2<CR>', opts)
map('n', '-', ':vertical resize -2<CR>', opts)

-- Tab navigation
map('n', ']t', ':tabnext<CR>', opts)
map('n', '[t', ':tabprev<CR>', opts)

-- Buffer navigation
map('n', ']b', ':bnext<CR>', opts)
map('n', '[b', ':bprevious<CR>', opts)

-- Split/window navigation
map('n', '<C-h>', '<C-w>h', opts)
map('n', '<C-j>', '<C-w>j', opts)
map('n', '<C-k>', '<C-w>k', opts)
map('n', '<C-l>', '<C-w>l', opts)

-- Explorer
map('n', '<leader>e', ':NvimTreeFindFileToggle<CR>', opts)
map('n', '<leader>n', '<cmd>NnnPicker<CR>', opts)

-- DAP / Debugging
local dap = require('dap')
map('n', '`b', dap.toggle_breakpoint, opts)
map('n', '`u', require('dapui').toggle, opts)
map('n', '`a', dap.attach, opts)
map('n', '`h', dap.continue, opts)
map('n', '`j', dap.step_over, opts)
map('n', '`i', dap.step_into, opts)
map('n', '`k', dap.step_out, opts)
map('n', '`q', function() dap.terminate({terminateDebugee = true}) end, opts)
map('n', '`s', function()
    require('telescope').extensions.dap.frames({initial_mode = 'normal'})
end, opts)

-- DAP terminal navigation
map('t', '<C-h>', '<C-\\><C-n><C-w>h', opts)
map('t', '<C-j>', '<C-\\><C-n><C-w>j', opts)
map('t', '<C-k>', '<C-\\><C-n><C-w>k', opts)
map('t', '<C-l>', '<C-\\><C-n><C-w>l', opts)

-- Telescope
local telescope = require('telescope.builtin');
map('n', '<leader>o', function() telescope.find_files({hidden = true, previewer = false}) end, opts)
map('n', '<leader>i', telescope.resume, opts)
map('n', '<leader>.',  function() telescope.find_files({cwd = '$HOME/.dotfiles', hidden = true}) end, opts)
map('n', '<leader>fb', telescope.current_buffer_fuzzy_find, opts)
map('n', '<leader>ff', telescope.live_grep, opts)
map('n', '<leader>fa', function()
    telescope.grep_string({
        search = vim.fn.input('  filter grep ❯ '),
        initial_mode = 'normal'
    })
end, opts)
map('n', '<leader>fw', function()
    telescope.grep_string({
        search = vim.fn.expand('<cword>'), initial_mode = 'normal'})
end, opts)
map('n', '<leader>gs', function() telescope.git_status({initial_mode = 'normal'}) end, opts)
map('n', '<leader>b', function() telescope.buffers({initial_mode = 'normal'}) end, opts)
map('n', '<leader>?', telescope.help_tags, opts)
map('n', '<leader>m', telescope.man_pages, opts)
map('n', '<leader>c',  telescope.commands, opts)

-- Git
-- Copy relative file path to clipboard
map('n', '<leader>p', ':let @+ = expand("%")<CR>', opts)
-- Checkout a different branch
map('n', '<leader>gcb', function() telescope.git_branches({initial_mode = 'normal'}) end, opts)
-- Next/previous hunk
map('n', ']h', '<cmd>Gitsigns next_hunk<CR>zz', opts)
map('n', '[h', '<cmd>Gitsigns prev_hunk<CR>zz', opts)
-- Preview hunk
map('n', '<leader>hp', '<cmd>Gitsigns preview_hunk<CR>', opts)
-- Reset hunk
map('n', '<leader>hu', '<cmd>Gitsigns reset_hunk<CR>', opts)
map('v', '<leader>hu', ':Gitsigns reset_hunk<CR>', opts)
-- Reset changes in the entire buffer
map('n', '<leader>hU', '<cmd>Gitsigns reset_buffer<CR>', opts)
-- Toggle git blame for the current line
map('n', '<leader>gB', '<cmd>Gitsigns toggle_current_line_blame<CR>', opts)
-- See blame history for the current file
map('n', '<leader>gbf', ':Git blame<CR>', opts)
-- Show git history for the current line
map('n', '<leader>gbl', ':GitBlameLine<CR>', opts)
-- Show git commit log
map('n', '<leader>gl', ':Gclog<CR>', opts)
-- Open current file changes in a vertical split.
-- This opens a 3-way diff if there are git conflict markers in the buffer.
map('n', '<leader>gds', ':Gvdiffsplit!<CR>', opts)
-- Compare current branch changes with main (populates quickfix list)
map('n', '<leader>gdm', ':Git difftool -y main<CR>', opts)
-- Compare with any branch
map('n', '<leader>gd', ':Git difftool -y', opts)

-- Conflict resolution
-- Choose which side to use for resolution
map('n', ']r', ':diffget //3<CR>', opts)
map('n', '[r', ':diffget //2<CR>', opts)

-- Find and replace
-- In current buffer
-- Type a replacement term and press . to repeat the replacement again. Useful
-- for replacing a few instances of the term (comparable to multiple cursors).
map('n', 'r', ":let @/='\\<'.expand('<cword>').'\\>'<CR>cgn", opts)
map('x', 'r', '"sy:let @/=@s<CR>cgn', opts)

-- Harpoons
local harpoon_ui = require('harpoon.ui')
map('n', '<leader>ha', require('harpoon.mark').add_file, opts)
map('n', '<leader>hh', harpoon_ui.toggle_quick_menu, opts)
map('n', '<leader>1', function() harpoon_ui.nav_file(1) end, opts)
map('n', '<leader>2', function() harpoon_ui.nav_file(2) end, opts)
map('n', '<leader>3', function() harpoon_ui.nav_file(3) end, opts)
map('n', '<leader>4', function() harpoon_ui.nav_file(4) end, opts)
