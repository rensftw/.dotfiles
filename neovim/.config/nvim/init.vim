" Automatically install Vim Plug
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" Set the correct encoding
scriptencoding utf-8
set encoding=utf-8

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Plugins
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
call plug#begin('~/.config/nvim/plugged')
" Additional language packs
Plug 'sheerun/vim-polyglot'
Plug 'leafOfTree/vim-vue-plugin'

" FZF integration with vim
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" Find and replace in multiple files (lazy loaded)
Plug 'mhinz/vim-grepper', { 'on': ['Grepper', '<plug>(GrepperOperator)'] }

" Tags
Plug 'ludovicchabant/vim-gutentags'

" Show a git diff in the sign column
Plug 'airblade/vim-gitgutter'

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
call plug#end()

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Theme/UI settings
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
syntax on
set t_Co=256
set cursorline
set splitright
set splitbelow
colorscheme dracula
let g:airline_theme='dracula'
let g:airline_powerline_fonts=1
let g:airline#extensions#tabline#enabled = 0
" :colors darkblue    " use for debugging theme-related issues
let g:javascript_plugin_jsdoc = 1
let g:python_highlight_all = 1
" Enable true colors, if possible
if exists('+termguicolors')
    let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
    let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
    set termguicolors
endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" General settings
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
filetype plugin indent on               " detect filetypes, apply filetype plugins, and indent files
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
" set termwinsize=20x0                    " terminal window uses 20 rows

" Cursor settings
" Solid underline cursor for normal mode and vertical bar for insert mode
" For iTerm (docs: https://iterm2.com/documentation-one-page.html)
" 0 - Block
" 1 - Vertical bar
" 2 - Underline
let &t_SI = "\<Esc>]1337;CursorShape=1\x7"
let &t_EI = "\<Esc>]1337;CursorShape=2\x7"

" Search highlighting
set hlsearch                            " highlight search results
set ignorecase                          " search case insensitive
set smartcase                           " only if there's uppercase letters
set incsearch                           " show results as you type
" Make double-<Esc> clear search highlights
nnoremap <silent><Esc><Esc>     <Esc>:nohlsearch<CR><Esc>

" Allow Y to work like C and D in normal mode
nnoremap <silent> Y             y$

" Enable wildmenu with completion
set wildmenu
" set wildmode=list:longest,full

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Plugin settings
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Vue syntax configuration
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

" GitGutter integration
let g:gitgutter_preview_win_floating = 1
" Show a hunk preview
nnoremap hp             :GitGutterPreviewHunk<CR>
" Jump between hunks
nnoremap ]h             :GitGutterNextHunk<CR>
nnoremap [h             :GitGutterPrevHunk<CR>
" Undo hunk
nnoremap hu             :GitGutterUndoHunk<CR>

" FZF configuration
let g:fzf_command_prefix = 'Fzf'
let g:fzf_action = {
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'enter': 'vsplit' }
" Open file (ctrl-t for new tab, ctrl-x and ctrl-v for new split)
nnoremap <silent><leader>o     :FZF -m<CR>
" Find term in file
vnoremap <leader>f              y/\V<C-R>=escape(@",'/\')<CR><CR>
" Find term in all files project-wide
nnoremap <leader>f      :FzfRg<CR>
" Inspect buffers
nnoremap <leader>b      :FzfBuffers<CR>
" Browse commands
nnoremap <leader>c      :FzfCommands<CR>

" Allow passing optional flags into the Rg command.
"   Example: :Rg myterm -g '*.md'
command! -bang -nargs=* Rg
  \ call fzf#vim#grep(
  \ "rg --column --line-number --no-heading --color=always --smart-case -g '!{node_modules/*,.git/*}' " .
  \ <q-args>, 1, fzf#vim#with_preview(), <bang>0)

" Grepper configuration
let g:grepper = {}
let g:grepper.tools = ["rg"]
xmap gr                 <plug>(GrepperOperator)

" Ultisnips configuration
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<tab>"
let g:UltiSnipsJumpBackwardTrigger="<s-tab>"
" If you want :UltiSnipsEdit to split your window.
let g:UltiSnipsEditSplit="vertical"

" ALE configuration
" Add remaps for linting and fixing
nnoremap <leader>al     :ALELint<CR>
nnoremap <leader>af     :ALEFix<CR>
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
" Show ALE status in airline
let g:airline#extensions#ale#enabled = 1
let g:airline#extensions#gutentags#enabled = 1
" Use the quickfix list instead of the loclist
let g:ale_set_loclist = 0
let g:ale_set_quickfix = 1
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
" Helper for toggling the terminal
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


" Basic autocommands
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

" Sensible remaps
" Prevent x from overriding what's in the clipboard.
noremap x               "_x
noremap X               "_x

" Prevent selecting and pasting from overwriting what you originally copied.
xnoremap p              pgvy

" Keep cursor at the bottom of the visual selection after you yank it.
vmap y                  ygv<Esc>

" Move 1 more lines up or down in normal and visual selection modes.
nnoremap K              :m .-2<CR>==
nnoremap J              :m .+1<CR>==
vnoremap K              :m '<-2<CR>gv=gv
vnoremap J              :m '>+1<CR>gv=gv

" Resize splits
nnoremap <S-Up>           :resize +2<CR>
nnoremap <S-Down>         :resize -2<CR>
nnoremap <S-Left>         :vertical resize +2<CR>
nnoremap <S-Right>        :vertical resize -2<CR>

" Terminal
" Toggle terminal on/off
nnoremap <leader>t      :call TermToggle(20)<CR>
tnoremap <leader>t      <C-\><C-n>:call TermToggle(12)<CR> 
inoremap <C-t>          <Esc>:call TermToggle(20)<CR>
" Navigate to/from terminal
tnoremap <C-h>          <C-\><C-N><C-w>h
tnoremap <C-j>          <C-\><C-N><C-w>j
tnoremap <C-k>          <C-\><C-N><C-w>k
tnoremap <C-l>          <C-\><C-N><C-w>l
" Go back to normal mode
tnoremap <esc>         <C-\><C-n>

" Normal remaps
nnoremap Q              !!$SHELL<CR>
nnoremap <leader>av     :tabnew $VIMRC_LOCATION<CR>     " augment vimrc
nnoremap <leader>az     :tabnew $ZSHRC_LOCATION<CR>     " augment zshrc
nnoremap <leader>rv     :source $VIMRC_LOCATION<CR>     " reload vimrc

" Shortcut tabs navigation
nnoremap tn             :tabnew<Space>
nnoremap tk             :tabnext<CR>
nnoremap tj             :tabprev<CR>
nnoremap th             :tabfirst<CR>
nnoremap tl             :tablast<CR>

" Shortcut for buffer navigation
nnoremap bn             :badd<Space>
nnoremap bk             :bnext<CR>
nnoremap bj             :bprevious<CR>
nnoremap bh             :bfirst<CR>
nnoremap bl             :blast<CR>

" Shortcut split/window navigation
nnoremap <C-h>          <C-w>h
nnoremap <C-j>          <C-w>j
nnoremap <C-k>          <C-w>k
nnoremap <C-l>          <C-w>l
" Cycle through splits.
" nnoremap ,              <C-w>w

" Shortcut split/window opening
nnoremap <leader>s      :split<Space>
nnoremap <leader>vs     :vsplit<Space>