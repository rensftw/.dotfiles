_Note: This setup has been tested only on macOS._


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
| Script                          | Description                                                                                         |
| :------------------------------ | :-------------------------------------------------------------------------------------------------- |
| `macos.sh`                      | Applies sensible macOS defaults.                                                                    |
| `install.sh`                    | Installs Homebrew and all formulae/casks defined in `Brewfile`.                                     |
| `configure.sh`                  | Configures tools and applies dotfiles.                                                              |
| `backup.sh`                     | Backs up `Brewfile` and global npm packages.                                                        |
| `uninstall.sh`                  | Removes all packages, tools, and config files.                                                      |

## Highlights
* [Alacritty](https://github.com/alacritty/alacritty) terminal emulator
* [`tmux`](https://github.com/tmux/tmux) + [`tpm`](https://github.com/tmux-plugins/tpm)
* [`neovim`](https://neovim.io/)
  * [`Lazy.nvim`](https://github.com/folke/lazy.nvim): Plugin manager
  * [`mason`](https://github.com/williamboman/mason.nvim): Package manager
  * [`telescope`](https://github.com/nvim-telescope/telescope.nvim): Fuzzy finder
  * [`treesitter`](https://github.com/nvim-treesitter/nvim-treesitter): AST goodies (syntax highlighting, AST playground with `:InspectTree`, incremental selection in normal mode, etc)
  * [`nvim-lspconfig`](https://github.com/neovim/nvim-lspconfig): Native LSP
  * [`nvim-dap`](https://github.com/mfussenegger/nvim-dap): Debugging protocol
  * [`folke/tokyonight.nvim` theme](https://github.com/folke/tokyonight.nvim): Theme
* [`nnn`](https://github.com/jarun/nnn) for terminal file navigation
* [`fzf`](https://github.com/junegunn/fzf) for fuzzy finding and interactive git operations
* [`rg`](https://github.com/BurntSushi/ripgrep) for searching file contents
* [`fd`](https://github.com/sharkdp/fd) for listing filesystem entries
* [`stow`](https://www.gnu.org/software/stow/) for dotfile management with symlinks
* [`brew`](https://brew.sh/) for macOS package management
* [`nvm`](https://github.com/nvm-sh/nvm) for Node version management
* [`BTOP++`](https://github.com/aristocratos/btop) for process monitoring
* [`AeroSpace`](https://github.com/nikitabobko/AeroSpace) as tiling window manager


### Screenshots
<details>
    <summary>Expand to see screenshots 📸</summary>
    <div>
        <p>
            <a href="https://github.com/romkatv/powerlevel10k/">Powerlevel10k</a> Rainbow prompt with modified <a href="https://github.com/folke/tokyonight.nvim">Tokyo Night</a> on <a href="https://github.com/alacritty/alacritty">Alacritty</a>
        </p>
        <img src="https://raw.githubusercontent.com/rensftw/.dotfiles-media/main/alacritty-tmux-powerlevel10k.png"/>
    </div>
    <br />
    <div>
        <p>Neovim with customized <a href="https://github.com/goolord/alpha-nvim">Alpha start screen</a> and dynamic quotes</p>
        <img src="https://raw.githubusercontent.com/rensftw/.dotfiles-media/main/tmux-neovim-alpha.png"/>
    </div>
    <br />
    <div>
        <p>Neovim with <a href="https://github.com/folke/tokyonight.nvim">Tokyo Night</a> theme showing LSP diagnostics and Git status:<p>
        <img src="https://raw.githubusercontent.com/rensftw/.dotfiles-media/main/neovim-null-ls-readme-demo.png"/>
    </div>
    <br />
    <div>
        <p>
            Interactive git operations with <a href="https://github.com/junegunn/fzf">fzf</a>
        </p>
        <p>
           <a target="_blank" href="https://user-images.githubusercontent.com/22574186/147154782-5b862118-34de-46fc-8331-4dcb4d975e7b.mp4">
           <img src="https://raw.githubusercontent.com/rensftw/.dotfiles-media/main/interactive-git-fzf-full-size.gif"/>
           </a>
        </p>
    </div>
    <br />
    <div>
        <p>BTOP++ for process monitoring:<p>
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

