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

" Coc / Intellisense
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" Documentation comments
Plug 'kkoomen/vim-doge', { 'do': { -> doge#install() } }

" Tags
Plug 'ludovicchabant/vim-gutentags'

" Git utilities
Plug 'tpope/vim-fugitive'

" Comment stuff out
Plug 'numToStr/Comment.nvim'

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
Plug 'dracula/vim', { 'as': 'dracula' }
Plug 'mhartington/oceanic-next'
Plug 'haishanh/night-owl.vim'
Plug 'Luxed/ayu-vim'

" Remove distractions
Plug 'junegunn/goyo.vim'

" Dev icons for coc-explorer (needs to be loaded last)
Plug 'ryanoasis/vim-devicons'
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

" Dracula configuration
let g:dracula_bold = 1
let g:dracula_italic = 1
let g:dracula_inverse = 1
let g:dracula_colorterm = 1

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

" CoC configuration
command! -nargs=0 Prettier :CocCommand prettier.formatFile
let g:coc_global_extensions = [
    \ 'coc-css',
    \ 'coc-emmet',
    \ 'coc-eslint',
    \ 'coc-explorer',
    \ 'coc-git',
    \ 'coc-highlight',
    \ 'coc-html',
    \ 'coc-json',
    \ 'coc-pairs',
    \ 'coc-prettier',
    \ 'coc-pyright',
    \ 'coc-sh',
    \ 'coc-snippets',
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

" Use tab for navigating snippets
inoremap <silent><expr> <TAB>
      \ pumvisible() ? coc#_select_confirm() :
      \ coc#expandableOrJumpable() ? "\<C-r>=coc#rpc#request('doKeymap', ['snippets-expand-jump',''])\<CR>" :
      \ <SID>check_back_space() ? "\<TAB>" :
      \ coc#refresh()

function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

let g:coc_snippet_next = '<tab>'

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
nnoremap <leader>t              :call TermToggle(20)<CR>
tnoremap <Esc>                  <C-\><C-n>:call TermToggle(12)<CR>
inoremap <C-t>                  <Esc>:call TermToggle(20)<CR>
" Navigate to/from terminal
tnoremap <C-h>                  <C-\><C-N><C-w>h
tnoremap <C-j>                  <C-\><C-N><C-w>j
tnoremap <C-k>                  <C-\><C-N><C-w>k
tnoremap <C-l>                  <C-\><C-N><C-w>l

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
nnoremap <leader>e               :CocCommand explorer<CR>

" Zen mode
nnoremap <leader>z               :Goyo<CR>

" Telescope
nnoremap <leader>o              <cmd>lua require('telescope.builtin').find_files({ hidden = true, previewer = false })<CR>
nnoremap <leader>w              <cmd>lua require('telescope.builtin').find_files({ cwd = "$HOME/work" })<CR>
nnoremap <leader>.              <cmd>lua require('telescope.builtin').find_files({ cwd = "$HOME/.dotfiles", hidden = true })<CR>
nnoremap <leader>f              <cmd>lua require('telescope.builtin').live_grep()<CR>
nnoremap <leader>b              <cmd>lua require('telescope.builtin').buffers()<CR>
nnoremap <leader>h              <cmd>lua require('telescope.builtin').help_tags()<CR>
nnoremap <leader>c              <cmd>lua require('telescope.builtin').commands()<CR>

" Git
" Copy remote URL to clipboard
nnoremap <leader>gu             :CocCommand git.copyUrl<CR>
" Copy relative file path to clipboard
nnoremap <leader>p              :let @+ = expand("%")<CR>
" See change history for the current file
nnoremap <leader>gb             :Git blame<CR>
" Open current file changes in a vertical split
nnoremap <leader>gs             :Gvdiffsplit!<CR>
" Compare current branch changes with main (populates quickfix list)
nnoremap <leader>gdm            :Git difftool -y main<CR>
" Compare with another branch
nnoremap <leader>gd             :Git difftool -y 

" Hunk navigation
nnoremap hp                     :CocCommand git.chunkInfo<CR>
nnoremap hu                     :CocCommand git.chunkUndo<CR>
nmap ]h                         <Plug>(coc-git-nextchunk)
nmap [h                         <Plug>(coc-git-prevchunk)

" Conflict resolution
" Navigate conflict markers
nmap ]c                         <Plug>(coc-git-nextconflict)
nmap [c                         <Plug>(coc-git-prevconflict)
" Choose which side to use for resolution
nnoremap [r                     :diffget //2<CR>
nnoremap ]r                     :diffget //3<CR>

" Find and replace
" In current buffer
" Type a replacement term and press . to repeat the replacement again. Useful
" for replacing a few instances of the term (comparable to multiple cursors).
nnoremap <silent>r              :let @/='\<'.expand('<cword>').'\>'<CR>cgn
xnoremap <silent>r              "sy:let @/=@s<CR>cgn
" Project-wide
nnoremap <leader>r              :CocSearch --smart-case 

" Coc / Intellisense
" Show all diagnostics in location list
nnoremap <silent><nowait> <leader>d        :<C-u>CocList diagnostics<CR>
" Navigate diagnostics
nmap <silent> [d                <Plug>(coc-diagnostic-prev)
nmap <silent> ]d                <Plug>(coc-diagnostic-next)

" GoTo code navigation
nmap <silent> gd                <Plug>(coc-definition)
nmap <silent> gy                <Plug>(coc-type-definition)
nmap <silent> gr                <Plug>(coc-references)

" Manage extensions
nnoremap <silent><nowait> <leader>ce        :<C-u>CocList extensions<CR>
" Search workspace symbols
nnoremap <silent><nowait> <leader>s         :<C-u>CocList -I symbols<CR>

" Apply codeAction to the current buffer.
nmap <leader>ca                 <Plug>(coc-codeaction)
" Apply AutoFix to problem on the current line.
nmap <leader>af                 <Plug>(coc-fix-current)
" Apply codeAction to the selected region.
" Example: `<leader>aap` for current paragraph
xmap <leader>a                  <Plug>(coc-codeaction-selected)
nmap <leader>a                  <Plug>(coc-codeaction-line)

" Symbol renaming.
nmap <leader>rn                 <Plug>(coc-rename)

" Format then loaded buffer.
xmap <leader>=                  <Plug>(coc-format)
nmap <leader>=                  <Plug>(coc-format)

