""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" General settings
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let mapleader=" "                       " use <space> as the leader key
set tabstop=4                           " show existing tab with 4 spaces width
set shiftwidth=4                        " when indenting with '>', use 4 spaces width
set expandtab                           " on pressing tab, insert 4 spaces
set softtabstop=4                       " edit as if tabs are 4 characters wide
set list                                " show invisible characters
set listchars=trail:·,tab:→\ ,nbsp:×    " define characters for showing whitespaces (eol:¬)
set updatetime=50                       " improve performance
set hidden                              " current buffer can be put into background
set autowrite                           " all modified buffers are written before closing
set wrap linebreak                      " wrap long lines
set number                              " show the current line number
set relativenumber                      " show relative line numbers
set nobackup                            " some servers have issues with backup files
set nowritebackup                       " do not make a backup before overwriting a file
set shortmess+=c                        " don't pass messages to |ins-completion-menu|
set signcolumn=yes                      " always show the sign column
set cursorline                          " highlight the line where the cursor is
set splitright                          " horizontal split should split to the right
set splitbelow                          " vertical split should split below
set completeopt=menuone,noinsert,noselect " do not auto-complete
" Enable true colors, if possible
if exists('+termguicolors')
    let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
    let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
    set termguicolors
endif

" Cursor shape/blinking settings
set guicursor=n-v-c:block-blinkwait175-blinkoff150-blinkon175,
    \i-ci-ve:ver25,
    \r-cr:hor20,
    \o:hor50,
    \a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor,
    \sm:block-blinkwait175-blinkoff150-blinkon175

" Search settings
set path+=**                            " search upwards and downwards the directory
set ignorecase                          " case-insensitive searching
set smartcase                           " case-sensitive if expresson contains a capital letters

" Ignore folders
set wildignore+=**/dist/*
set wildignore+=**/coverage/*
set wildignore+=**/node_modules/*
set wildignore+=**/.git/*
set wildignore+=*.pyc
set wildignore+=*build/*

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Imports
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
lua require 'plugins'
runtime ./keymaps.vim
runtime ./autocommands.vim

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Plugin settings
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:tokyonight_style = 'night'
let g:tokyonight_lualine_bold = 'true'
colorscheme tokyonight

lua require 'plugin/lualine-rc'
lua require 'plugin/nvim-treesitter-rc'
lua require 'plugin/telescope-rc'
lua require 'plugin/trouble-rc'
lua require 'plugin/nvim-tree-rc'
lua require 'plugin/lspsaga-rc'
lua require 'plugin/lspconfig-rc'
lua require 'plugin/nvim-cmp-rc'
lua require 'plugin/gitsigns-rc'
lua require 'plugin/ultisnips-rc'
lua require 'plugin/doge-rc'
lua require 'plugin/autopairs-rc'
lua require 'plugin/alpha-rc'

lua require 'Comment'.setup()
lua require 'colorizer'.setup()
lua require 'toggleterm'.setup()

