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
vnoremap <leader>y              "*y 

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

" Conflict resolution
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
" Formatting + fixing all autofixable stuff ?
