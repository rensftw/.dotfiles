_Note: So far, this setup has been tailored for and tested only on macOS._  

## Download
With git (recommended):
```sh
xcode-select --install              # required for clean installations, because macOS is not shipped with git
softwareupdate --install-rosetta    # required for Apple Silicon-based machines
git clone https://github.com/rensftw/.dotfiles.git
```


Git-free download:
```sh
mkdir .dotfiles && cd .dotfiles && curl -L https://api.github.com/repos/rensftw/.dotfiles/tarball | tar xz --strip=1
```


## Scripts
There are 4 main scripts for managing this setup:
* `install.sh`:       Installs Homebrew and all formulae/casks defined in Brewfile.
* `configure.sh`:     Fetches and configures additional tools.
* `backup.sh`:        Backs up `Brewfile`, [`Code`](https://code.visualstudio.com/) extensions, and global npm packages.
* `uninstall.sh`:     Removes all global packages, tools, and config files


Feeling adventurous? Try the entire setup as is.  
There are comments/mnemonics for documenting each keybinding in `.aliases` (look out for some cool git tricks 🧙‍♀️)


## Tailor this setup to your likes (partial install)
Feel free to fork this repo and customize it to your own needs 🏎   
Here are some useful tips for getting started:  
* Pick and choose what tools/software to install from [Brewfile](./_homebrew/Brewfile).
* Directories starting with an underscore (`_`) contain helper scripts.
* All other directories are `stow` packages and contain dotfiles.
* Stow allows symlinking individual packages, for example: `stow -vt ~ zsh` will symlink only `zsh`-related config files.


## Highlights
* [`neovim nightly`](https://neovim.io/) + [`telescope`](https://github.com/nvim-telescope/telescope.nvim) + [`coc`](https://github.com/neoclide/coc.nvim) for code editing
* [`ranger`](https://github.com/ranger/ranger) for terminal file navigation
* [`fzf`](https://github.com/junegunn/fzf) for fuzzy finding and interactive git operations
* [`rg`](https://github.com/BurntSushi/ripgrep) for searching file contents
* [`fd`](https://github.com/sharkdp/fd) for listing filesystem entries
* [`stow`](https://www.gnu.org/software/stow/) for dotfile management with symlinks
* [`brew`](https://brew.sh/) for macOS package management
* [`nvm`](https://github.com/nvm-sh/nvm) for Node version management
* [`BpyTOP`](https://github.com/aristocratos/bpytop) for process monitoring
* [`slate`](https://github.com/jigish/slate) for window management


## Screenshots
[Powerlevel10k](https://github.com/romkatv/powerlevel10k/) Rainbow prompt with [Glacier](https://github.com/bahlo/iterm-colors#glacier) theme on [iTerm2](https://iterm2.com/):
![Powerlevel10k Rainbow prompt with Glacier theme on iTerm2](https://raw.githubusercontent.com/rensftw/.dotfiles-media/main/rainbow-prompt-with-glacier-theme.png)


(Neo)vim with [Dracula](https://draculatheme.com/vim) theme:
![(Neo)vim with Dracula theme](https://raw.githubusercontent.com/rensftw/.dotfiles-media/main/vim-with-dracula-theme.png)


Interactive git operations with fzf:
![Staging git changes interactively, using fzf bindings](https://raw.githubusercontent.com/rensftw/.dotfiles-media/main/interactive-git-fzf-full-size.gif)


BpyTOP for process monitoring:
![BpyTOP for process monitoring](https://raw.githubusercontent.com/rensftw/.dotfiles-media/main/bpytop-process-manager.png)

