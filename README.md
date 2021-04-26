## Installation
Clean (installs XCode command line tools and git):
```
mkdir .dotfiles && cd .dotfiles && curl -L https://api.github.com/repos/rensftw/.dotfiles/tarball | tar xz --strip=1
```
  
As a git repo:   
```
xcode-select --install
git clone https://github.com/rensftw/.dotfiles.git
```
  
## Setting up a new machine
This setup has been tailored for and tested on macOS.  
There are 3 main scripts:  
* `install.sh`: Installs tools/software using [`brew`](https://brew.sh/) and sets up config files using [`stow`](https://www.gnu.org/software/stow/)
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

