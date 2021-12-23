local map = vim.api.nvim_set_keymap

local opts = {noremap = true, silent = true}

map('n', 'Q', ':wqall<CR>', opts)
map('n', 'W', ':wall<CR>', opts)

-- Delete all other buffers
map('n', 'B', ':BufOnly<CR>', opts)

-- Make double-<Esc> clear search highlights
map('n', '<Esc><Esc>', '<Esc>:nohlsearch<CR><Esc>', opts)

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

-- Copy to the shared register
map('n', '<leader>y', '"+yiw', opts)
map('v', '<leader>y', '"*y', opts)

-- Move 1 or more lines up or down in normal and visual selection modes.
map('n', 'K', ':m .-2<CR>==', opts)
map('n', 'J', ':m .+1<CR>==', opts)
map('v', 'K', ":m '<-2<CR>gv=gv", opts)
map('v', 'J', ":m '>+1<CR>gv=gv", opts)

-- Resize splits
map('n', '<S-up>', ':resize +2<CR>', opts)
map('n', '<S-down', ':resize -3<CR>', opts)
map('n', '<S-right>', ':vertical resize +2<CR>', opts)
map('n', '<S-left>', ':vertical resize -2<CR>', opts)

-- Terminal
-- Toggle terminal on/off
map('n', '<C-\\>', ':ToggleTerm size=20 direction=horizontal<CR>', opts)
map('t', '<C-\\>', '<C-\\><C-n>:ToggleTermToggleAll<CR>', opts)
map('t', '<C-t>', '<C-\\><C-n> 2:ToggleTerm<CR>', opts)
map('i', '<C-t>', '<Esc>:ToggleTerm size=20 direction=horizontal<CR>', opts)
-- Navigate to/from terminal
map('t', '<C-h>', '<C-\\><C-n><C-w>h', opts)
map('t', '<C-j>', '<C-\\><C-n><C-w>j', opts)
map('t', '<C-k>', '<C-\\><C-n><C-w>k', opts)
map('t', '<C-l>', '<C-\\><C-n><C-w>l', opts)

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

-- Telescope
map('n', '<leader>o', '<cmd>lua require("telescope.builtin").find_files({ hidden = true, previewer = false })<CR>', opts)
map('n', '<leader>w', '<cmd>lua require("telescope.builtin").find_files({ cwd = "$HOME/work" })<CR>', opts)
map('n', '<leader>.', '<cmd>lua require("telescope.builtin").find_files({ cwd = "$HOME/.dotfiles", hidden = true })<CR>', opts)
map('n', '<leader>f', '<cmd>lua require("telescope.builtin").live_grep()<CR>', opts)
map('n', '<leader>g', '<cmd>lua require("telescope.builtin").git_status()<CR>', opts)
map('n', '<leader>b', '<cmd>lua require("telescope.builtin").buffers()<CR>', opts)
map('n', '<leader>?', '<cmd>lua require("telescope.builtin").help_tags()<CR>', opts)
map('n', '<leader>c', '<cmd>lua require("telescope.builtin").commands()<CR>', opts)

-- Preview markdown
map('n', '<leader>mp', ':Glow<CR>', opts)

-- Git
-- Copy relative file path to clipboard
map('n', '<leader>p', ':let @+ = expand("%")<CR>', opts)
-- See blame history for the current file
map('n', '<leader>gB', ':Git blame<CR>', opts)
-- Open current file changes in a vertical split
map('n', '<leader>gs', ':Gvdiffsplit!<CR>', opts)
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

-- Diagnostics
map('n', '<leader>D', ':TroubleToggle<CR>', opts)

