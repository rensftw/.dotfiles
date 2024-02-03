--  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = ' ' -- use <space> as the leader key
vim.o.mouse = '' -- disable mouse support
vim.o.tabstop = 4 -- show existing tab with 4 spaces width
vim.o.shiftwidth = 4 -- when indenting with '>', use 4 spaces width
vim.o.softtabstop = 4 -- edit as if tabs are 4 characters wide
vim.o.expandtab = true -- on pressing tab, insert 4 spaces
vim.o.updatetime = 50 -- improve performance
vim.o.hidden = true -- current buffer can be put into background
vim.o.autowrite = true -- all modified buffers are written before closing
vim.o.wrap = false -- do NOT wrap long lines
vim.o.number = true -- show the current line number
vim.o.relativenumber = true -- show relative line numbers
vim.o.backup = false -- some servers have issues with backup files
vim.o.writebackup = false -- do not make a backup before overwriting a file
vim.o.shortmess = 'c' -- don't pass messages to |ins-completion-menu|
vim.o.signcolumn = 'yes' -- always show the sign column
vim.o.cursorline = true -- highlight the line where the cursor is
vim.o.splitright = true -- horizontal split should split to the right
vim.o.splitbelow = true -- vertical split should split below
vim.opt.completeopt = { 'menuone' , 'noinsert', 'noselect' } -- do not auto-complete
vim.o.laststatus = 3 -- show one global statusline
vim.o.scroll = 10 -- <ctrl-d> and <ctrl-u> should scroll by 10 lines
vim.opt.scrolloff = 8 -- minimal number of screen lines to keep above and below the cursor
vim.opt.errorbells = false -- do not ring the bell for error messages (beep or screen flash)
vim.opt.smartindent = true -- smart indent when starting a new line
vim.opt.swapfile = false -- do not create swapfiles
vim.opt.updatetime = 50 -- blazingly fast (default is 4000ms)
vim.opt.colorcolumn = '80'
vim.o.undofile = true -- save undo history
vim.o.undodir = vim.fn.stdpath('state') .. 'undodir'

-- Folds: Use foldmethod indent by default (fallback to treesitter)
-- source: https://essais.co/better-folding-in-neovim/
-- za: toggle fold (based on indentation)
-- zM: close all folds in the buffer
-- zR: open all folds in the buffer
vim.opt.foldmethod = 'expr'
vim.opt.foldenable = false
-- TODO: Remove this hotfix once issue is resolved in Neovim repo
-- https://github.com/neovim/neovim/issues/25608
-- vim.wo.foldexpr = 'nvim_treesitter#foldexpr()'
vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
-- source: https://github.com/abzcoding/lvim/blob/a4e400f0ffaba68377cca432566e54617dfeb2ca/lua/user/neovim.lua#L52
vim.wo.foldtext =
[[substitute(getline(v:foldstart),'\\t',repeat('\ ',&tabstop),'g').'...'.trim(getline(v:foldend)) . ' (' . (v:foldend - v:foldstart + 1) . ' lines)']]

-- Enable folding for :Man pages
vim.g.ft_man_folding_enable = true

-- Show invisible characters
vim.opt.list = true
vim.opt.listchars = {
    -- space = '·',
    -- eol = '↴',
    trail = '·',
    tab = '→ ',
    nbsp = '×',
}

-- Diff options
vim.opt.diffopt ={
    'vertical', -- show diff in vertical mode
    'filler', -- show filler for deleted lines
}

-- Enable true colors, if possible
vim.o.termguicolors = true

-- Search settings
vim.opt.path:append({'**' }) -- search upwards and downwards the directory
vim.o.ignorecase = true -- case-insensitive searching
vim.o.smartcase = true -- case-sensitive if expresson contains a capital letters

-- Grep settings
-- example search with glob pattern:
-- grep 'return this.items' --glob '*.js'
vim.o.grepprg = 'rg --vimgrep --no-heading --smart-case'
vim.o.grepformat = '%f:%l:%c:%m'

-- Ignore folders
vim.opt.wildignore ={  '**/dist/*',
    '**/coverage/*',
    '**/node_modules/*',
    '**/.git/*',
    '*.pyc',
    '*build/*'
}
