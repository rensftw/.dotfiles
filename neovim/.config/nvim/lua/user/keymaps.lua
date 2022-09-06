local map = vim.keymap.set

local opts = { silent = true }

map('n', 'Q', ':wqall<CR>', opts)
map('n', 'W', ':wall<CR>', opts)

-- Delete all other buffers
map('n', 'B', ':BufOnly<CR>', opts)

-- Close all other tabs
map('n', 'T', ':tabonly<CR>', opts)

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

-- Copy to the shared register
map('n', '<leader>y', '"+yiw', opts)
map('v', '<leader>y', '"*y', opts)

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

-- Navigation shortcuts
map('n', '<leader>av', ':tabnew $VIMRC_LOCATION<CR>', opts)
map('n', '<leader>az', ':tabnew $ZSHRC_LOCATION<CR>', opts)
map('n', '<leader>aa', ':tabnew $ALIASES_LOCATION<CR>', opts)
map('n', '<leader>rv', ':source $VIMRC_LOCATION<CR>', opts)

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

-- DAP / Debugging
map('n', '<Tab>b', '<cmd>lua require("dap").toggle_breakpoint()<CR>', opts)
map('n', '<Tab>u', '<cmd>lua require("dapui").toggle()<CR>', opts)
map('n', '<Tab>a', '<cmd>lua require("dap").attach()<CR>', opts)
map('n', '<Tab>h', '<cmd>lua require("dap").continue()<CR>', opts)
map('n', '<Tab>j', '<cmd>lua require("dap").step_over()<CR>', opts)
map('n', '<Tab>i', '<cmd>lua require("dap").step_into()<CR>', opts)
map('n', '<Tab>k', '<cmd>lua require("dap").step_out()<CR>', opts)
map('n', '<Tab>q', '<cmd>lua require("dap").terminate({terminateDebugee = true})<CR>', opts)
map('n', '<Tab>s', '<cmd>lua require("telescope").extensions.dap.frames({initial_mode = "normal"})<CR>', opts)

-- DAP terminal navigation
map('t', '<C-h>', '<C-\\><C-n><C-w>h', opts)
map('t', '<C-j>', '<C-\\><C-n><C-w>j', opts)
map('t', '<C-k>', '<C-\\><C-n><C-w>k', opts)
map('t', '<C-l>', '<C-\\><C-n><C-w>l', opts)

-- Telescope
map('n', '<leader>o', '<cmd>lua require("telescope.builtin").find_files({hidden = true, previewer = false})<CR>', opts)
-- map('n', '<leader>oa', '<cmd>lua require("telescope.builtin").find_files({hidden = true, no_ignore = true, previewer = false})<CR>', opts)
map('n', '<leader>.', '<cmd>lua require("telescope.builtin").find_files({cwd = "$HOME/.dotfiles", hidden = true})<CR>',
    opts)
map('n', '<leader>fb', '<cmd>lua require("telescope.builtin").current_buffer_fuzzy_find()<CR>', opts)
map('n', '<leader>ff', '<cmd>lua require("telescope.builtin").live_grep()<CR>', opts)
map('n', '<leader>fa',
    '<cmd>lua require("telescope.builtin").grep_string({search = vim.fn.input("  filter grep ❯ "), initial_mode = "normal"})<CR>'
    , opts)
map('n', '<leader>fw',
    '<cmd>lua require("telescope.builtin").grep_string({search = vim.fn.expand("<cword>"), initial_mode = "normal"})<CR>'
    , opts)
map('n', '<leader>gs', '<cmd>lua require("telescope.builtin").git_status({initial_mode = "normal"})<CR>', opts)
map('n', '<leader>b', '<cmd>lua require("telescope.builtin").buffers({initial_mode = "normal"})<CR>', opts)
map('n', '<leader>?', '<cmd>lua require("telescope.builtin").help_tags()<CR>', opts)
map('n', '<leader>c', '<cmd>lua require("telescope.builtin").commands()<CR>', opts)

-- Git
-- Copy relative file path to clipboard
map('n', '<leader>p', ':let @+ = expand("%")<CR>', opts)
-- Next/previous hunk
map('n', ']h', '<cmd>Gitsigns next_hunk<CR>', opts)
map('n', '[h', '<cmd>Gitsigns prev_hunk<CR>', opts)
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
map('n', '<leader>ha', '<cmd>lua require("harpoon.mark").add_file()<CR>', opts)
map('n', '<leader>hh', '<cmd>lua require("harpoon.ui").toggle_quick_menu()<CR>', opts)
map('n', '<leader>1', '<cmd>lua require("harpoon.ui").nav_file(1)<CR>', opts)
map('n', '<leader>2', '<cmd>lua require("harpoon.ui").nav_file(2)<CR>', opts)
map('n', '<leader>3', '<cmd>lua require("harpoon.ui").nav_file(3)<CR>', opts)
map('n', '<leader>4', '<cmd>lua require("harpoon.ui").nav_file(4)<CR>', opts)
