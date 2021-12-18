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
Plug 'tami5/lspsaga.nvim'
Plug 'folke/trouble.nvim'
Plug 'hrsh7th/nvim-cmp'
" completion sources:
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'

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
Plug 'Luxed/ayu-vim'

" Colorizer for CSS files
Plug 'norcalli/nvim-colorizer.lua'

" Remove distractions
Plug 'junegunn/goyo.vim'
call plug#end()
