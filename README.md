_Note: This setup is built for and tested on macOS._


## Download
With git (recommended):
```sh
xcode-select --install              # required for clean installations, because macOS is not shipped with git
softwareupdate --install-rosetta    # required for Apple Silicon-based machines
git clone https://github.com/rensftw/.dotfiles.git
```


Without git:
```sh
mkdir .dotfiles && cd .dotfiles && curl -L https://api.github.com/repos/rensftw/.dotfiles/tarball | tar xz --strip=1
```


## Scripts
|Script                         |Description                                                                                        |
|:------------------------------|:--------------------------------------------------------------------------------------------------|
| `apply-macos-preferences.sh`  | Applies sensible macOS defaults.                                                                  |
| `install.sh`                  | Installs Homebrew and all formulae/casks defined in `Brewfile`.                                   |
| `configure.sh`                | Configures tools and applies dotfiles.                                                            |
| `backup.sh`                   | Backs up `Brewfile`, [`Code`](https://code.visualstudio.com/) extensions, and global npm packages.|
| `uninstall.sh`                | Removes all packages, tools, and config files.                                                    |


## Highlights
* [`neovim`](https://neovim.io/) + [`packer`](https://github.com/wbthomason/packer.nvim) + [`telescope`](https://github.com/nvim-telescope/telescope.nvim)
* [`ranger`](https://github.com/ranger/ranger) for terminal file navigation
* [`fzf`](https://github.com/junegunn/fzf) for fuzzy finding and interactive git operations
* [`rg`](https://github.com/BurntSushi/ripgrep) for searching file contents
* [`fd`](https://github.com/sharkdp/fd) for listing filesystem entries
* [`stow`](https://www.gnu.org/software/stow/) for dotfile management with symlinks
* [`brew`](https://brew.sh/) for macOS package management
* [`nvm`](https://github.com/nvm-sh/nvm) for Node version management
* [`BpyTOP`](https://github.com/aristocratos/bpytop) for process monitoring
* [`Rectangle`](https://github.com/rxhanson/Rectangle) for window management


### Screenshots
<details>
    <summary>Expand 📸</summary>
    <div>
        <p>
            <a href="https://github.com/romkatv/powerlevel10k/">Powerlevel10k</a> Rainbow prompt with modified <a href="https://github.com/folke/tokyonight.nvim">Tokyo Night</a> on <a href="https://iterm2.com/">iTerm</a>
        </p>
        <img src="https://raw.githubusercontent.com/rensftw/.dotfiles-media/main/iterm-with-modified-tokyonight-theme.png"/>
    </div>
    <div>
        <p>Neovim with <a href="https://github.com/folke/tokyonight.nvim">Tokyo Night</a> theme:<p>
        <img src="https://raw.githubusercontent.com/rensftw/.dotfiles-media/main/neovim-with-tokyonight-theme.png"/>
    </div>
    <div>
        <p>Interactive git operations with fzf:</p>
        https://user-images.githubusercontent.com/22574186/147154782-5b862118-34de-46fc-8331-4dcb4d975e7b.mp4
        <embed
            src="https://user-images.githubusercontent.com/22574186/147154782-5b862118-34de-46fc-8331-4dcb4d975e7b.mp4"
            autostart="false"
            height="600"
            width="800"
        />
    </div>
    <div>
        <p>BpyTOP for process monitoring:<p>
        <img src="https://raw.githubusercontent.com/rensftw/.dotfiles-media/main/bpytop-process-manager.png" />
    </div>
</details>


## Tailor this setup to your likes (partial install)
> [`.aliases`](./system/.aliases) has interactive git commands and other magic tricks.

Feel free to fork this repo and customize it to your own needs 🏎   
Tips for getting started:  
* Pick and choose what tools/software to install from [Brewfile](./_homebrew/Brewfile).
* Directories starting with an underscore (`_`) contain helper scripts.
* All other directories are `stow` packages and contain dotfiles.
* Stow allows symlinking individual packages, for example: `stow -vt ~ zsh` will symlink only `zsh`-related config files.

