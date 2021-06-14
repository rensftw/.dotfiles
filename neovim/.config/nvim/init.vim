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
" Additional language packs
Plug 'sheerun/vim-polyglot'
Plug 'leafOfTree/vim-vue-plugin'

" Treesitter (AST-based syntax highlighting)
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

" Telescope
Plug 'kyazdani42/nvim-web-devicons'
Plug 'nvim-lua/popup.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'make' }
Plug 'nvim-telescope/telescope.nvim'

" Find and replace in multiple files (lazy loaded)
Plug 'mhinz/vim-grepper', { 'on': ['Grepper', '<plug>(GrepperOperator)'] }

" Tags
Plug 'ludovicchabant/vim-gutentags'

" Git utilities
Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-fugitive'

" Comment stuff out
Plug 'tpope/vim-commentary'

" Change, delete, add surroundings (parentheses, brackets, quotes, tags)
Plug 'tpope/vim-surround'

" Mappings for complementary commands like ]q, [q, etc
Plug 'tpope/vim-unimpaired'

" Allow vim-surround and vim-unimpaired commands to be repeated with .
Plug 'tpope/vim-repeat'

" Briefly highlight which text was yanked
Plug 'machakann/vim-highlightedyank'

" Automatic closing of quotes, parenthesis, brackets, etc.
Plug 'jiangmiao/auto-pairs'

" Add indentation that closely matches PEP 8
Plug 'vim-scripts/indentpython'

" Custom snippets
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'

" Lint and fix-on-save
Plug 'dense-analysis/ale'

" Respect .editorconfig
Plug 'editorconfig/editorconfig-vim'

" Airline
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" Themes
Plug 'dracula/vim', { 'as': 'dracula' }
Plug 'flazz/vim-colorschemes'
Plug 'mhartington/oceanic-next'
Plug 'haishanh/night-owl.vim'
call plug#end()

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" General settings
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" let mapleader = " "
set tabstop=4                           " show existing tab with 4 spaces width
set shiftwidth=4                        " when indenting with '>', use 4 spaces width
set expandtab                           " on pressing tab, insert 4 spaces
set softtabstop=4                       " edit as if tabs are 4 characters wide
set list                                " show invisible characters
set listchars=trail:·,tab:→\ ,nbsp:×    " define characters for showing whitespaces (eol:¬)
set updatetime=50                       " improve performance
set hidden                              " current buffer can be put into background
set wrap linebreak
set number                              " show the current line number
set relativenumber                      " show relative line numbers 
set t_Co=256                            " explicitly tell vim that the terminal supports 256 colors
set cursorline
set splitright
set splitbelow
colorscheme OceanicNext
" :colors darkblue    " use for debugging theme-related issues
" Enable true colors, if possible
if exists('+termguicolors')
    let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
    let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
    set termguicolors
endif

" Cursor settings
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
" Dracula settings
let g:dracula_bold = 1
let g:dracula_italic = 1
let g:dracula_inverse = 1
let g:dracula_colorterm = 1

" Airline settings
let g:airline_theme = 'night_owl'
let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#ale#enabled = 1
let g:airline#extensions#gutentags#enabled = 1
let g:airline#extensions#wordcount#enabled = 1
let g:airline#extensions#hunks#non_zero_only = 1

" Syntax configurations
let g:javascript_plugin_jsdoc = 1
let g:python_highlight_all = 1
let g:vim_vue_plugin_config = {
      \'syntax': {
      \   'template': ['html'],
      \   'script': ['javascript'],
      \   'style': ['css'],
      \},
      \'full_syntax': [],
      \'initial_indent': [],
      \'attribute': 0,
      \'keyword': 0,
      \'foldexpr': 0,
      \'debug': 0,
      \}

" Treesitter
lua require "rensftw-nvim-treesitterrc"

" Telescope
nnoremap <leader>o              <cmd>lua require('telescope.builtin').find_files({ hidden = true })<cr>
nnoremap <leader>fg             <cmd>lua require('telescope.builtin').live_grep()<cr>
nnoremap <leader>b              <cmd>lua require('telescope.builtin').buffers()<cr>
nnoremap <leader>h              <cmd>lua require('telescope.builtin').help_tags()<cr>
nnoremap <leader>c              <cmd>lua require('telescope.builtin').commands()<cr>

" Telescope's config
lua require "rensftw-telescoperc"

" GitGutter integration
let g:gitgutter_preview_win_floating = 1
" Show a hunk preview
nnoremap hp                     :GitGutterPreviewHunk<CR>
" Jump between hunks
nnoremap ]h                     :GitGutterNextHunk<CR>
nnoremap [h                     :GitGutterPrevHunk<CR>
" Undo hunk
nnoremap hu                     :GitGutterUndoHunk<CR>

" Grepper configuration
let g:grepper = {}
let g:grepper.tools = ["rg"]
xmap gr                         <plug>(GrepperOperator)

" Ultisnips configuration
let g:UltiSnipsExpandTrigger = "<tab>"
let g:UltiSnipsJumpForwardTrigger = "<tab>"
let g:UltiSnipsJumpBackwardTrigger = "<s-tab>"
" If you want :UltiSnipsEdit to split your window.
let g:UltiSnipsEditSplit = "vertical"

" ALE configuration
" Add remaps for linting and fixing
nnoremap <leader>al             :ALELint<CR>
nnoremap <leader>af             :ALEFix<CR>
" Linting and fixing
let g:ale_enabled = 1
" Enable autocomplete
let g:ale_completion_enabled = 1
" Lint when opening a file and when a file is modified
let g:ale_lint_on_enter = 1
let g:ale_lint_on_text_changed = 'always'
" Do not lint when saving/closing a file
let g:ale_lint_on_save = 0
" Do not automatically fix - fixing should be intentional/manual
let g:ale_fix_on_save = 0
" Show ALE errors in the sign column
let g:ale_sign_column_always = 1
let g:ale_set_loclist = 1
let g:ale_set_quickfix = 0
let g:ale_hover_to_preview = 1
" Apply JS setting for Vue files as well
let g:ale_linter_aliases = {'javascript': ['vue', 'javascript']}
let g:ale_linters = {
\   'javascript': ['eslint', 'tsserver'],
\   'typescript': ['eslint'],
\   'html': ['prettier'],
\   'css': ['prettier'],
\   'json': ['prettier'],
\   'python': ['flake8'],
\}
let g:ale_fixers = {
\   '*': ['remove_trailing_lines', 'trim_whitespace'],
\   'markdown': [],
\   'javascript': ['eslint'],
\   'typescript': ['eslint'],
\   'html': ['prettier'],
\   'css': ['prettier'],
\   'json': ['prettier'],
\   'python': ['black'],
\}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Utilities
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helper for toggling the native terminal
let g:term_buf = 0
let g:term_win = 0
function! TermToggle(height)
    if win_gotoid(g:term_win)
        hide
    else
        botright new
        exec "resize " . a:height
        try
            exec "buffer " . g:term_buf
        catch
            call termopen($SHELL, {"detach": 0})
            let g:term_buf = bufnr("")
            set nonumber
            set norelativenumber
            set signcolumn=no
        endtry
        startinsert!
        let g:term_win = win_getid()
    endif
endfunction

" Find and replace in current file
" Type a replacement term and press . to repeat the replacement again. Useful
" for replacing a few instances of the term (comparable to multiple cursors).
nnoremap <silent>r      :let @/='\<'.expand('<cword>').'\>'<CR>cgn
xnoremap <silent>r      "sy:let @/=@s<CR>cgn

" Find and replace project-wide
" After searching for text, press this mapping to do a project wide find and
" replace. It's similar to <leader>r except this one applies to all matches
" across all files instead of just the current file.
nnoremap <leader>R
  \ :let @s='\<'.expand('<cword>').'\>'<CR>
  \ :Grepper -cword -noprompt<CR>
  \ :cfdo %s/<C-r>s//g \| update
  \<Left><Left><Left><Left><Left><Left><Left><Left><Left><Left><Left>

" The same as above except it works with a visual selection.
xmap <leader>R
    \ "sy
    \ gvgr
    \ :cfdo %s/<C-r>s//g \| update
     \<Left><Left><Left><Left><Left><Left><Left><Left><Left><Left><Left>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Autocommands
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Auto-resize splits when Vim gets resized.
autocmd VimResized * wincmd =

" Update a buffer's contents on focus if it changed outside of Vim.
au FocusGained,BufEnter * :checktime

" Update GitGutter's status after entering another window (the terminal window)
au WinEnter * :GitGutterAll

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
command! BufOnly execute 'wa | %bdelete | edit # | normal `"'

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Remaps
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Make double-<Esc> clear search highlights
nnoremap <silent><Esc><Esc>     <Esc>:nohlsearch<CR><Esc>

" Allow Y to work like C and D in normal mode
nnoremap <silent> Y             y$

" Prevent x from overriding what's in the clipboard.
noremap x                       "_x
noremap X                       "_x

" Prevent selecting and pasting from overwriting what you originally copied.
xnoremap p                      pgvy

" Keep cursor at the bottom of the visual selection after you yank it.
vmap y                          ygv<Esc>

" Move 1 more lines up or down in normal and visual selection modes.
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
nnoremap <leader>t              :call TermToggle(20)<CR>
tnoremap <leader>t              <C-\><C-n>:call TermToggle(12)<CR> 
inoremap <C-t>                  <Esc>:call TermToggle(20)<CR>
" Navigate to/from terminal
tnoremap <C-h>                  <C-\><C-N><C-w>h
tnoremap <C-j>                  <C-\><C-N><C-w>j
tnoremap <C-k>                  <C-\><C-N><C-w>k
tnoremap <C-l>                  <C-\><C-N><C-w>l
" Go back to normal mode
tnoremap <esc>                  <C-\><C-n>

" Normal remaps
nnoremap Q                      !!$SHELL<CR>
nnoremap <leader>av             :tabnew $VIMRC_LOCATION<CR>     " augment init.vim
nnoremap <leader>az             :tabnew $ZSHRC_LOCATION<CR>     " augment zshrc
nnoremap <leader>aa             :tabnew $ALIASES_LOCATION<CR>   " augment aliases
nnoremap <leader>rv             :source $VIMRC_LOCATION<CR>     " reload vimrc

" Shortcut tabs navigation
nnoremap tn                     :tabnew<Space>
nnoremap ]t                     :tabnext<CR>
nnoremap [t                     :tabprev<CR>

" Buffer navigation
nnoremap ]b                     :bnext<CR>
nnoremap [b                     :bprevious<CR>

" Shortcut split/window navigation
nnoremap <C-h>                  <C-w>h
nnoremap <C-j>                  <C-w>j
nnoremap <C-k>                  <C-w>k
nnoremap <C-l>                  <C-w>l

" Git conflict resolution
nnoremap <leader>gb             :Git blame<CR>
nnoremap <leader>gd             :Gvdiffsplit!<CR>
nnoremap <leader>gdm            :Git difftool -y master<CR>
nnoremap <leader>gh             :GitGutterLineHighlightsToggle<CR>
nnoremap gd[                    :diffget //2<CR>
nnoremap gd]                    :diffget //3<CR>
