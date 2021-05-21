## Installation
Without VCS:
```sh
mkdir .dotfiles && cd .dotfiles && curl -L https://api.github.com/repos/rensftw/.dotfiles/tarball | tar xz --strip=1
```
  
With git:  
```sh
xcode-select --install  # required for clean installations, because macOS is not shipped with git
git clone https://github.com/rensftw/.dotfiles.git
```
  
## Highlights
* [`ranger`](https://github.com/ranger/ranger) for terminal file navigation
* [`fzf`](https://github.com/junegunn/fzf) integration with vim and aliases for interactive git operations
* [`rg`](https://github.com/BurntSushi/ripgrep) for searching
* [`stow`](https://www.gnu.org/software/stow/) for dotfile management with symlinks
* [`brew`](https://brew.sh/) for macOS package management
* [`nvm`](https://github.com/nvm-sh/nvm) for Node version management
* [`BpyTOP`](https://github.com/aristocratos/bpytop) for process monitoring
  
## Setting up a new machine
This setup has been tailored for and tested on macOS.  
There are 3 main scripts:  
* `install.sh`: Installs tools/software and sets up config files
* `backup.sh`: Backs up `Brewfile`, [`Code`](https://code.visualstudio.com/) extensions, and global npm packages
* `uninstall.sh`: Removes all global packages, tools, and config files

  
## Using this setup
Feel free to fork this repo and customize it to your own needs!  
Here's some useful information for getting started:  
* Directories starting with an underscore (_) contain helpers
* All other directories are `stow` packages
  
## Screenshots
[Powerlevel10k](https://github.com/romkatv/powerlevel10k/) Rainbow prompt with [Glacier](https://github.com/bahlo/iterm-colors#glacier) theme on [iTerm2](https://iterm2.com/):
![Powerlevel10k Rainbow prompt with Glacier theme on iTerm2](https://raw.githubusercontent.com/rensftw/.dotfiles-media/main/rainbow-prompt-with-glacier-theme.png)
  
Vim with [Dracula](https://draculatheme.com/vim) theme:
![Vim with Dracula theme](https://raw.githubusercontent.com/rensftw/.dotfiles-media/main/vim-with-dracula-theme.png)
  
Interactive staging with a preview window for git (using fzf bindings):  
There are also bindings for:
  * unstaging changes
  * discarding changes
  * inspecting stash entries
  * inspecting the git history of a branch (with commit preview)
  * switching between branches

![Staging git changes interactively, using fzf bindings](https://raw.githubusercontent.com/rensftw/.dotfiles-media/main/interactive-git-fzf-full-size.gif)

  
BpyTOP for process monitoring:
![BpyTOP for process monitoring](https://raw.githubusercontent.com/rensftw/.dotfiles-media/main/bpytop-process-manager.png)

