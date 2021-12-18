runtime ./plug.vim

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
" Ayu theme (ayu config needs to be before colorscheme definition)
let g:ayu_italic_comment = 1
let g:ayucolor = 'dark'
colorscheme ayu
" :colors darkblue    " use for debugging theme-related issues

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
" Plugin settings
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" OceanicNext configuration
let g:oceanic_next_terminal_bold = 1
let g:oceanic_next_terminal_italic = 1

" Goyo configuration
let g:goyo_width = 120
let g:goyo_height = 90
let g:goyo_linenr = 1

" Documentation comments
let g:doge_mapping = '<leader>jd'
let g:doge_filetype_aliases = {
\  'javascript': [
\    'vue',
\    'javascript.jsx',
\    'javascriptreact',
\    'javascript.tsx',
\    'typescriptreact',
\    'typescript',
\    'typescript.tsx',
\    ]
\}

let g:doge_javascript_settings = {
\  'destructuring_props': 1,
\  'omit_redundant_param_types': 0,
\}

lua require('lualine-rc')
lua require('nvim-treesitter-rc')
lua require('telescope-rc')
lua require('trouble-rc')
lua require('nvim-tree-rc')
lua require('lspconfig-rc')
lua require('nvim-cmp-rc')
lua require('gitsigns-rc')
lua require('ultisnips-rc')

lua require('Comment').setup()
lua require('nvim-autopairs').setup()
lua require('colorizer').setup()
lua require('toggleterm').setup()

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Autocommands
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Auto-resize splits when Vim gets resized.
autocmd VimResized * wincmd =

" Update a buffer's contents on focus if it changed outside of Vim.
au FocusGained,BufEnter * :checktime

" Unset paste on InsertLeave.
autocmd InsertLeave * silent! set nopaste

" Make sure all types of requirements.txt files get syntax highlighting.
autocmd BufNewFile,BufRead requirements*.txt set ft=python

" Make sure .aliases, .bash_aliases and similar files get syntax highlighting.
autocmd BufNewFile,BufRead .*aliases* set ft=sh

" Ensure tabs don't get converted to spaces in Makefiles.
autocmd FileType make setlocal noexpandtab

" Only show the cursor line in the active buffer.
augroup CursorLine
    au!
    au VimEnter,WinEnter,BufWinEnter * setlocal cursorline
    au WinLeave * setlocal nocursorline
augroup END

" Write all changes to modified buffers,
" close all buffers except the active one,
" and return focus to the same spot it was initially
command! BufOnly execute 'wa | %bdelete | edit # | bdelete # | normal `"'

runtime ./keymaps.vim
