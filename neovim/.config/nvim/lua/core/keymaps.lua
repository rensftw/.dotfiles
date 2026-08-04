local map = vim.keymap.set
local opts = { noremap = true, silent = true }
local center_after_scroll =
    '<Cmd>lua require("mini.animate").execute_after("scroll", "normal! zz")<CR>'

map('n', 'Q', ':wqall<CR>', opts)
map('n', 'W', ':wall<CR>', opts)

-- Clears hlsearch after doing a search, otherwise just does normal <CR> stuff
map('n', '<CR>', function()
    return vim.v.hlsearch == 1 and ':nohl<CR>' or '<CR>'
end, { expr = true, silent = true, nowait = true })

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

-- Center scrolling and navigation
map('n', '<C-d>', '<C-d>' .. center_after_scroll, opts)
map('n', '<C-u>', '<C-u>' .. center_after_scroll, opts)
map('n', '<C-o>', '<C-o>' .. center_after_scroll, opts)
map('n', '<C-i>', '<C-i>' .. center_after_scroll, opts)

-- Center search results
map('n', 'n', 'n' .. center_after_scroll, opts)
map('n', 'N', 'N' .. center_after_scroll, opts)
map('n', '*', '*' .. center_after_scroll, opts)
map('n', '#', '#' .. center_after_scroll, opts)
map('n', 'g*', 'g*' .. center_after_scroll, opts)
map('n', 'g#', 'g#' .. center_after_scroll, opts)

-- Center quickfix results when navigating
map('n', ']q', '<cmd>cnext<CR>' .. center_after_scroll, opts)
map('n', '[q', '<cmd>cprev<CR>' .. center_after_scroll, opts)

-- Center fold navigation
map('n', 'zj', 'zj' .. center_after_scroll, opts)
map('n', 'zk', 'zk' .. center_after_scroll, opts)

-- Move 1 or more lines up or down in normal and visual selection modes.
map('n', 'K', ':m .-2<CR>==', opts)
map('n', 'J', ':m .+1<CR>==', opts)
map('v', 'K', ":m '<-2<CR>gv=gv", opts)
map('v', 'J', ":m '>+1<CR>gv=gv", opts)

-- Resize window using <ctrl> arrow keys
map('n', '<A-Up>', '<cmd>resize +2<cr>', { desc = 'Increase window height' })
map('n', '<A-Down>', '<cmd>resize -2<cr>', { desc = 'Decrease window height' })
map('n', '<A-Left>', '<cmd>vertical resize -2<cr>', { desc = 'Decrease window width' })
map('n', '<A-Right>', '<cmd>vertical resize +2<cr>', { desc = 'Increase window width' })

-- Tab navigation
map('n', ']t', ':tabnext<CR>', opts)
map('n', '[t', ':tabprev<CR>', opts)

-- Buffer navigation
map('n', ']b', ':bnext<CR>', opts)
map('n', '[b', ':bprevious<CR>', opts)

-- Git
-- Copy relative file path to clipboard
map('n', '<leader>p', ':let @+ = expand("%")<CR>', opts)
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
