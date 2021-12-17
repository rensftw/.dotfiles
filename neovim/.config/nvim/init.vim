" Automatically install Vim Plug
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Plugins
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
call plug#begin('~/.config/nvim/plugged')
" Treesitter (AST-based syntax highlighting)
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

" Telescope
Plug 'kyazdani42/nvim-web-devicons'
Plug 'nvim-lua/popup.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'make' }
Plug 'nvim-telescope/telescope.nvim'

" File explorer
Plug 'kyazdani42/nvim-tree.lua'

" LSP
Plug 'neovim/nvim-lspconfig'
Plug 'hrsh7th/nvim-cmp'
Plug 'folke/trouble.nvim'
" completion sources:
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'

" Snippets
Plug 'SirVer/ultisnips'
Plug 'quangnguyen30192/cmp-nvim-ultisnips'

" Documentation comments
Plug 'kkoomen/vim-doge', { 'do': { -> doge#install() } }

" Tags
Plug 'ludovicchabant/vim-gutentags'

" Git utilities
Plug 'tpope/vim-fugitive'
Plug 'lewis6991/gitsigns.nvim'

" Toggle-able terminal
Plug 'akinsho/toggleterm.nvim'

" Comment stuff out
Plug 'numToStr/Comment.nvim'

" Autopairs
Plug 'windwp/nvim-autopairs'

" Change, delete, add surroundings (parentheses, brackets, quotes, tags)
Plug 'tpope/vim-surround'

" Mappings for complementary commands like ]q, [q, etc
Plug 'tpope/vim-unimpaired'

" Allow vim-surround and vim-unimpaired commands to be repeated with .
Plug 'tpope/vim-repeat'

" Briefly highlight which text was yanked
Plug 'machakann/vim-highlightedyank'

" Add indentation that closely matches PEP 8
Plug 'vim-scripts/indentpython'

" Respect .editorconfig
Plug 'editorconfig/editorconfig-vim'

" Lualine
Plug 'nvim-lualine/lualine.nvim'

" Themes
Plug 'mhartington/oceanic-next'
Plug 'haishanh/night-owl.vim'
Plug 'Luxed/ayu-vim'

" Colorizer for CSS files
Plug 'norcalli/nvim-colorizer.lua'

" Remove distractions
Plug 'junegunn/goyo.vim'
call plug#end()

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

" Lualine configuration
lua require "lualine-rc"

" Treesitter configuration
lua require "nvim-treesitter-rc"

" Telescope configuration
lua require "telescope-rc"

" Comment.nvim configuration
lua require('Comment').setup()
lua require('nvim-autopairs').setup()
lua require('colorizer').setup()
lua require('toggleterm').setup()
lua require "trouble-rc"

" File navigator configuration
lua require "nvim-tree-rc"

" LSP
lua require "lspconfig-rc"

" Completion
lua require "nvim-cmp-rc"

" Git signs
lua require "gitsigns-rc"

" Ultisnips config
let g:UltiSnipsJumpForwardTrigger="<tab>"
let g:UltiSnipsJumpBackwardTrigger="<s-tab>"

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

" " Coc
" " Highlight the symbol and its references when holding the cursor.
" autocmd CursorHold * silent call CocActionAsync('highlight')
"
" " Add `:Format` command to format current buffer.
" command! -nargs=0 Format :call CocAction('format')
"
" " Add `:Fold` command to fold current buffer.
" command! -nargs=? Fold :call     CocAction('fold', <f-args>)
"
" " Add `:OR` command for organize imports of the current buffer.
" command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Remaps
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Make double-<Esc> clear search highlights
nnoremap <silent><Esc><Esc>     <Esc>:nohlsearch<CR><Esc>

" Prevent x from overriding what's in the clipboard.
noremap x                       "_x
noremap X                       "_x

" Prevent selecting and pasting from overwriting what you originally copied.
xnoremap p                      pgvy

" Keep cursor at the bottom of the visual selection after you yank it.
vmap y                          ygv<Esc>

" Copy to the shared register
nnoremap <leader>y              "+yiw

" Move 1 or more lines up or down in normal and visual selection modes.
nnoremap K                      :m .-2<CR>==
nnoremap J                      :m .+1<CR>==
vnoremap K                      :m '<-2<CR>gv=gv
vnoremap J                      :m '>+1<CR>gv=gv

" Resize splits
nnoremap <S-Up>                 :resize +2<CR>
nnoremap <S-Down>               :resize -2<CR>
nnoremap <S-Left>               :vertical resize +2<CR>
nnoremap <S-Right>              :vertical resize -2<CR>

" Terminal
" Toggle terminal on/off
nnoremap <tab>                  :ToggleTerm size=20 direction=horizontal<CR>
tnoremap <S-tab>                <C-\><C-n>:ToggleTermToggleAll<CR>
tnoremap <C-t>                  <C-\><C-n> 2:ToggleTerm<CR>
inoremap <C-t>                  <Esc>:ToggleTerm size=20 direction=horizontal<CR>
" Navigate to/from terminal
tnoremap <C-h>                  <C-\><C-n><C-w>h
tnoremap <C-j>                  <C-\><C-n><C-w>j
tnoremap <C-k>                  <C-\><C-n><C-w>k
tnoremap <C-l>                  <C-\><C-n><C-w>l

" Normal remaps
nnoremap Q                      !!$SHELL<CR>
nnoremap <leader>av             :tabnew $VIMRC_LOCATION<CR>     " augment init.vim
nnoremap <leader>az             :tabnew $ZSHRC_LOCATION<CR>     " augment zshrc
nnoremap <leader>aa             :tabnew $ALIASES_LOCATION<CR>   " augment aliases
nnoremap <leader>rv             :source $VIMRC_LOCATION<CR>     " reload vimrc

" Tab navigation
nnoremap ]t                     :tabnext<CR>
nnoremap [t                     :tabprev<CR>

" Buffer navigation
nnoremap ]b                     :bnext<CR>
nnoremap [b                     :bprevious<CR>

" Split/window navigation
nnoremap <C-h>                  <C-w>h
nnoremap <C-j>                  <C-w>j
nnoremap <C-k>                  <C-w>k
nnoremap <C-l>                  <C-w>l

" Explorer
nnoremap <leader>e               :NvimTreeFindFileToggle<CR>

" Zen mode
nnoremap <leader>z               :Goyo<CR>

" Telescope
nnoremap <leader>o              <cmd>lua require('telescope.builtin').find_files({ hidden = true, previewer = false })<CR>
nnoremap <leader>w              <cmd>lua require('telescope.builtin').find_files({ cwd = "$HOME/work" })<CR>
nnoremap <leader>.              <cmd>lua require('telescope.builtin').find_files({ cwd = "$HOME/.dotfiles", hidden = true })<CR>
nnoremap <leader>f              <cmd>lua require('telescope.builtin').live_grep()<CR>
nnoremap <leader>b              <cmd>lua require('telescope.builtin').buffers()<CR>
nnoremap <leader>?              <cmd>lua require('telescope.builtin').help_tags()<CR>
nnoremap <leader>c              <cmd>lua require('telescope.builtin').commands()<CR>

" Git
" Copy remote URL to clipboard
" nnoremap <leader>gu             :CocCommand git.copyUrl<CR>
" Copy relative file path to clipboard
nnoremap <leader>p              :let @+ = expand("%")<CR>
" See change history for the current file
nnoremap <leader>gB             :Git blame<CR>
" Open current file changes in a vertical split
nnoremap <leader>gs             :Gvdiffsplit!<CR>
" Compare current branch changes with main (populates quickfix list)
nnoremap <leader>gdm            :Git difftool -y main<CR>
" Compare with another branch
nnoremap <leader>gd             :Git difftool -y 

" " Conflict resolution
" " Navigate conflict markers
" nmap ]c                         <Plug>(coc-git-nextconflict)
" nmap [c                         <Plug>(coc-git-prevconflict)
" Choose which side to use for resolution
nnoremap [r                     :diffget //2<CR>
nnoremap ]r                     :diffget //3<CR>

" Find and replace
" In current buffer
" Type a replacement term and press . to repeat the replacement again. Useful
" for replacing a few instances of the term (comparable to multiple cursors).
nnoremap <silent>r              :let @/='\<'.expand('<cword>').'\>'<CR>cgn
xnoremap <silent>r              "sy:let @/=@s<CR>cgn

" Diagnostics
nnoremap <leader>d              :TroubleToggle<CR>

" Project-wide
" nnoremap <leader>r              :CocSearch --smart-case 
" Formatting + fixing all autofixable stuff
" xmap <leader>=                  <Plug>(coc-format)
" nmap <leader>=                  <Plug>(coc-format)
"
