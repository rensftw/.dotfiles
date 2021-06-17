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

" Coc / Intellisense
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" Find and replace in multiple files (lazy loaded)
Plug 'mhinz/vim-grepper', { 'on': ['Grepper', '<plug>(GrepperOperator)'] }

" Tags
Plug 'ludovicchabant/vim-gutentags'

" Git utilities
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

" Add indentation that closely matches PEP 8
Plug 'vim-scripts/indentpython'

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
set autowrite                           " all modified buffers are written before closing
set wrap linebreak                      " wrap long lines
set number                              " show the current line number
set relativenumber                      " show relative line numbers
set nobackup                            " some servers have issues with backup files
set nowritebackup                       " do not make a backup before overwriting a file
set shortmess+=c                        " don't pass messages to |ins-completion-menu|
set signcolumn=yes                      " always show the sign column
set cursorline                          " highlight the line where the cursor is
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

" Dracula configuration
let g:dracula_bold = 1
let g:dracula_italic = 1
let g:dracula_inverse = 1
let g:dracula_colorterm = 1

" Airline configuration
let g:airline_theme = 'oceanicnext'
let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#gutentags#enabled = 1
let g:airline#extensions#wordcount#enabled = 1
let g:airline#extensions#hunks#non_zero_only = 1

" Syntax configuration
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

" Treesitter configuration
lua require "nvim-treesitter-rc"

" Telescope's configuration
lua require "telescope-rc"

" CoC configuration
command! -nargs=0 Prettier :CocCommand prettier.formatFile
let g:coc_global_extensions = [
    \ 'coc-css',
    \ 'coc-eslint',
    \ 'coc-explorer',
    \ 'coc-git',
    \ 'coc-highlight',
    \ 'coc-html',
    \ 'coc-json',
    \ 'coc-snippets',
    \ 'coc-pairs',
    \ 'coc-prettier',
    \ 'coc-pyright',
    \ 'coc-sh',
    \ 'coc-swagger',
    \ 'coc-tag',
    \ 'coc-tsserver',
    \ 'coc-vetur',
    \ 'coc-xml',
    \ 'coc-yaml',
    \ ]

" Add (Neo)Vim's native statusline support.
set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}

" Use tab for trigger completion with characters ahead and navigate.
inoremap <silent><expr><TAB>
      \ pumvisible() ? "\<C-n>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()
inoremap <expr><S-TAB>          pumvisible() ? "\<C-p>" : "\<C-h>"

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" Use <c-space> to trigger completion.
inoremap <silent><expr>         <c-space> coc#refresh()

" Make <CR> auto-select the first completion item and notify coc.nvim to
" format on enter, <cr> could be remapped by other vim plugin
inoremap <silent><expr> <cr> pumvisible() ? coc#_select_confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

" Grepper configuration
let g:grepper = {}
let g:grepper.tools = ["rg"]
xmap gr                         <plug>(GrepperOperator)

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

" Coc
" Highlight the symbol and its references when holding the cursor.
autocmd CursorHold * silent call CocActionAsync('highlight')

" Add `:Format` command to format current buffer.
command! -nargs=0 Format :call CocAction('format')

" Add `:Fold` command to fold current buffer.
command! -nargs=? Fold :call     CocAction('fold', <f-args>)

" Add `:OR` command for organize imports of the current buffer.
command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')

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

" Explorer
nnoremap <leader>e               :CocCommand explorer<CR>

" Telescope
nnoremap <leader>o              <cmd>lua require('telescope.builtin').find_files({ hidden = true })<cr>
nnoremap <leader>ow             <cmd>lua require('telescope.builtin').find_files({ cwd = "$HOME/work" })<cr>
nnoremap <leader>od             <cmd>lua require('telescope.builtin').find_files({ cwd = "$HOME/.dotfiles", hidden = true })<cr>
nnoremap <leader>fg             <cmd>lua require('telescope.builtin').live_grep()<cr>
nnoremap <leader>b              <cmd>lua require('telescope.builtin').buffers()<cr>
nnoremap <leader>h              <cmd>lua require('telescope.builtin').help_tags()<cr>
nnoremap <leader>c              <cmd>lua require('telescope.builtin').commands()<cr>

" Git
" Copy remote URL to clipboard
nnoremap <leader>gu             :CocCommand git.copyUrl<CR>

" Hunk navigation
nnoremap hp                     :CocCommand git.chunkInfo<CR>
nnoremap hu                     :CocCommand git.chunkUndo<CR>
nmap ]h                         <Plug>(coc-git-nextchunk)
nmap [h                         <Plug>(coc-git-prevchunk)

" Conflict resolution
nmap ]c                         <Plug>(coc-git-nextconflict)
nmap [c                         <Plug>(coc-git-prevconflict)
nnoremap <leader>gb             :Git blame<CR>
nnoremap <leader>gp             :Gvdiffsplit!<CR>
nnoremap <leader>gdm            :Git difftool -y master<CR>
nnoremap <leader>gd             :Git difftool -y 
nnoremap gd[                    :diffget //2<CR>
nnoremap gd]                    :diffget //3<CR>

" Coc / Intellisense
" Show all diagnostics in location list
nnoremap <silent><nowait> <leader>d        :<C-u>CocList diagnostics<cr>
" Navigate diagnostics
nmap <silent> [d                <Plug>(coc-diagnostic-prev)
nmap <silent> ]d                <Plug>(coc-diagnostic-next)

" GoTo code navigation
nmap <silent> gd                <Plug>(coc-definition)
nmap <silent> gy                <Plug>(coc-type-definition)
nmap <silent> gr                <Plug>(coc-references)

" Manage extensions
nnoremap <silent><nowait> <leader>ce        :<C-u>CocList extensions<cr>
" Search workspace symbols
nnoremap <silent><nowait> <leader>fs        :<C-u>CocList -I symbols<cr>

" Apply codeAction to the current buffer.
nmap <leader>ca                 <Plug>(coc-codeaction)
" Apply AutoFix to problem on the current line.
nmap <leader>cf                 <Plug>(coc-fix-current)
" Apply codeAction to the selected region.
" Example: `<leader>aap` for current paragraph
xmap <leader>a                  <Plug>(coc-codeaction-selected)
nmap <leader>a                  <Plug>(coc-codeaction-selected)

" Symbol renaming.
nmap <leader>rn                 <Plug>(coc-rename)

" Formatting selected code.
xmap <leader>f                  <Plug>(coc-format-selected)
nmap <leader>f                  <Plug>(coc-format-selected)

