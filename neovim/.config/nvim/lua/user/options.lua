vim.g.mapleader = ' ' -- use <space> as the leader key
vim.o.mouse = '' -- disable mouse support
vim.o.tabstop = 4 -- show existing tab with 4 spaces width
vim.o.shiftwidth = 4 -- when indenting with '>', use 4 spaces width
vim.o.softtabstop = 4 -- edit as if tabs are 4 characters wide
vim.o.expandtab = true -- on pressing tab, insert 4 spaces
vim.o.updatetime = 50 -- improve performance
vim.o.hidden = true -- current buffer can be put into background
vim.o.autowrite = true -- all modified buffers are written before closing
vim.o.wrap = true -- wrap long lines
vim.o.number = true -- show the current line number
vim.o.relativenumber = true -- show relative line numbers
vim.o.backup = false -- some servers have issues with backup files
vim.o.writebackup = false -- do not make a backup before overwriting a file
vim.o.shortmess = 'c' -- don't pass messages to |ins-completion-menu|
vim.o.signcolumn = 'yes' -- always show the sign column
vim.o.cursorline = true -- highlight the line where the cursor is
vim.o.splitright = true -- horizontal split should split to the right
vim.o.splitbelow = true -- vertical split should split below
vim.o.completeopt = 'menuone,noinsert,noselect' -- do not auto-complete
vim.o.laststatus = 3 -- show one global statusline

-- Folds
-- source: https://essais.co/better-folding-in-neovim/
-- za: toggle fold (based on indentation)
-- zM: close all folds in the buffer
-- zR: open all folds in the buffer
vim.api.nvim_exec([[
    set foldexpr=nvim_treesitter#foldexpr()
]], true)
vim.opt.foldmethod = 'indent'
vim.opt.foldenable = false
vim.opt.foldlevel = 99
vim.opt.fillchars = 'fold: '
vim.api.nvim_exec([[
    set foldtext=CustomFoldText()

    function! CustomFoldText()
      let indentation = indent(v:foldstart - 1)
      let foldSize = 1 + v:foldend - v:foldstart
      let foldSizeStr = " " . foldSize . " lines "
      let foldLevelStr = repeat("+--", v:foldlevel)
      let expansionString = repeat(" ", indentation)

      return expansionString . foldLevelStr . foldSizeStr
    endfunction
]], true)

-- Show invisible characters
vim.o.list = true
-- vim.opt.listchars:append('space:·')
-- vim.opt.listchars:append('eol:↴')
vim.opt.listchars:append('trail:·')
vim.opt.listchars:append('tab:→ ')
vim.opt.listchars:append('nbsp:×')

-- Diff options
vim.o.diffopt = ''
vim.o.diffopt = vim.o.diffopt .. 'vertical,' -- show diff in vertical mode
vim.o.diffopt = vim.o.diffopt .. 'filler' -- show filler for deleted lines

-- Enable true colors, if possible
vim.o.termguicolors = true
vim.g['&t_8f'] = '\\<Esc>[38;2;%lu;%lu;%lum'
vim.g['&t_8b'] = '\\<Esc>[48;2;%lu;%lu;%lum'

-- -- Cursor shape/blinking settings
-- vim.o.guicursor = 'n-v-c:block-blinkwait175-blinkoff150-blinkon175,'
-- vim.o.guicursor = vim.o.guicursor .. 'i-ci-ve:ver25,'
-- vim.o.guicursor = vim.o.guicursor .. 'r-cr:hor20,'
-- vim.o.guicursor = vim.o.guicursor .. 'o:hor50,'
-- vim.o.guicursor = vim.o.guicursor .. 'a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor,'
-- vim.o.guicursor = vim.o.guicursor .. 'sm:block-blinkwait175-blinkoff150-blinkon175'

-- Search settings
vim.o.path = vim.o.path .. '**' -- search upwards and downwards the directory
vim.o.ignorecase = true -- case-insensitive searching
vim.o.smartcase = true -- case-sensitive if expresson contains a capital letters

-- Grep settings
-- example search with glob pattern:
-- grep 'return this.items' --glob '*.js'
vim.o.grepprg = 'rg --vimgrep --no-heading --smart-case'
vim.o.grepformat = '%f:%l:%c:%m'

-- Ignore folders
vim.o.wildignore = '**/dist/*'
vim.o.wildignore = vim.o.wildignore .. '**/coverage/*'
vim.o.wildignore = vim.o.wildignore .. '**/node_modules/*'
vim.o.wildignore = vim.o.wildignore .. '**/.git/*'
vim.o.wildignore = vim.o.wildignore .. '*.pyc'
vim.o.wildignore = vim.o.wildignore .. '*build/*'
