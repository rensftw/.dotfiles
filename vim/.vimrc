" Automatically install Vim Plug
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" Set the correct encoding
scriptencoding utf-8
set encoding=utf-8

" Plugins
call plug#begin('~/.vim/plugged')
" Additional language packs
Plug 'sheerun/vim-polyglot'

" FZF integration with vim
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" Find and replace in multiple files (lazy loaded)
Plug 'mhinz/vim-grepper', { 'on': ['Grepper', '<plug>(GrepperOperator)'] }

" Show a git diff in the sign column
Plug 'airblade/vim-gitgutter'

" Comment stuff out
Plug 'tpope/vim-commentary'

" Briefly highlight which text was yanked
Plug 'machakann/vim-highlightedyank'

" Automatic closing of quotes, parenthesis, brackets, etc.
Plug 'Raimondi/delimitMate'

" Change, delete, add surroundings (parentheses, brackets, quotes, tags)
Plug 'tpope/vim-surround'

" Mappings for complementary commands like ]q, [q, etc
Plug 'tpope/vim-unimpaired'

" Add identation that closely matches PEP 8
Plug 'vim-scripts/indentpython'

" Custom snippets
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'

" Lint and fix-on-save
Plug 'dense-analysis/ale'

" Airline
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" Themes
Plug 'dracula/vim', { 'as': 'dracula' }
call plug#end()

" Theme/UI
syntax on
set t_Co=256
set cursorline
set splitright
set splitbelow
colorscheme dracula
let g:airline_theme='dracula'
let g:airline_powerline_fonts=1
" :colors darkblue    " use for debugging theme-related issues
let g:python_highlight_all = 1
" Enable true colors
if exists('+termguicolors')
let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
set termguicolors
endif

" General settings
filetype plugin indent on
set nocompatible
set tabstop=4                           " show existing tab with 4 spaces width
set shiftwidth=4                        " when indenting with '>', use 4 spaces width
set expandtab                           " on pressing tab, insert 4 spaces
set softtabstop=4
set list                                " show trailing whitespaces
set listchars=trail:·,tab:»»,nbsp:×     " define characters for showing whitespaces
set updatetime=100
set backspace=indent,eol,start
set wrap linebreak
set number
set relativenumber
set rtp+=/usr/local/opt/fzf


" Git integration
" Jump between hunks
nmap h <Plug>(GitGutterNextHunk)
nmap H <Plug>(GitGutterPrevHunk)

" Search highlighting
" highlight search results
set hlsearch
" Make double-<Esc> clear search highlights
nnoremap <silent> <Esc><Esc> <Esc>:nohlsearch<CR><Esc>

" FZF configuration
let g:fzf_command_prefix = 'Fzf'
let g:fzf_action = {
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'enter': 'vsplit' }
" Open file (ctrl-t for new tab, ctrl-x and ctrl-v for new split)
nnoremap <silent><leader>o     :FZF -m<CR>
" Find term in file
nnoremap f                      *
vnoremap f                      y/\V<C-R>=escape(@",'/\')<CR><CR>
" Find term in all files project-wide
nnoremap <leader>f              :FzfRg<CR>
" Inspect buffers
nnoremap <leader>b              :FzfBuffers<CR>

" Allow passing optional flags into the Rg command.
"   Example: :Rg myterm -g '*.md'
command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
  \ "rg --column --line-number --no-heading --color=always --smart-case " .
  \ <q-args>, 1, fzf#vim#with_preview(), <bang>0)

" Grepper configuration
let g:grepper={}
let g:grepper.tools=["rg"]
xmap gr <plug>(GrepperOperator)

" Find and replace in current file
" Press * to search for the term under the cursor or a visual selection and
" then press a key below to replace all instances of it in the current file.
nnoremap <leader>r :%s///g<Left><Left>

" Find and replace project-wide
" After searching for text, press this mapping to do a project wide find and
" replace. It's similar to <leader>r except this one applies to all matches
" across all files instead of just the current file.
nnoremap <Leader>R
  \ :let @s='\<'.expand('<cword>').'\>'<CR>
  \ :Grepper -cword -noprompt<CR>
  \ :cfdo %s/<C-r>s//g \| update
  \<Left><Left><Left><Left><Left><Left><Left><Left><Left><Left><Left>

" The same as above except it works with a visual selection.
xmap <Leader>R
    \ "sy
    \ gvgr
    \ :cfdo %s/<C-r>s//g \| update
     \<Left><Left><Left><Left><Left><Left><Left><Left><Left><Left><Left>

" Snippets (trigger configuration)
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<tab>"
let g:UltiSnipsJumpBackwardTrigger="<s-tab>"
" If you want :UltiSnipsEdit to split your window.
let g:UltiSnipsEditSplit="vertical"

" Linting and fixing
let g:ale_enabled = 1
" Lint when opening a file
let g:ale_lint_on_enter = 1
" Lint when the file is changed
let g:ale_lint_on_text_changed = 'always'
" Do not lint when saving/closing a file
let g:ale_lint_on_save = 0
" Fix lint error on file save
let g:ale_fix_on_save = 1
let g:ale_sign_column_always = 1
let g:airline#extensions#ale#enabled = 1
" Use the quickfix list instead of the loclist
let g:ale_set_loclist = 0
let g:ale_set_quickfix = 1
let g:ale_hover_to_preview = 0
" Add remaps for linting and fixing
nnoremap <leader>al      :ALELint<CR>
nnoremap <leader>af      :ALEFix<CR>
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

" Normal remaps
nnoremap Q              !!$SHELL<CR>
nnoremap <leader>t      :below terminal<CR>
" Exit terminal mode
tnoremap <leader>T      <C-\><C-n>
nnoremap <leader>av     :tabnew $VIMRC_LOCATION<CR>     " augment vimrc
nnoremap <leader>az     :tabnew $ZSHRC_LOCATION<CR>     " augment zshrc
nnoremap <leader>rv     :source $VIMRC_LOCATION<CR>     " reload vimrc

" Shortcut tabs navigation
nnoremap tn             :tabnew<Space>
nnoremap tk             :tabnext<CR>
nnoremap tj             :tabprev<CR>
nnoremap th             :tabfirst<CR>
nnoremap tl             :tablast<CR>

" Shortcut split/window navigation
nnoremap <C-h>          <C-w>h
nnoremap <C-j>          <C-w>j
nnoremap <C-k>          <C-w>k
nnoremap <C-l>          <C-w>l

" Shortcut split/window opening
nnoremap <leader>s      :split<Space>
nnoremap <leader>vs     :vsplit<Space>
