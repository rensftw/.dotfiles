# Dotfiles

Personal macOS dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/) and Homebrew.

> Tested only on macOS. The scripts are intentionally opinionated and install/remove real applications, shell config, and macOS preferences. Read `./_homebrew/Brewfile`, `./macos.sh`, and `./uninstall.sh` before running them on a machine you care about.

## Quick start

```sh
# 1. Install Apple command line tools. Required on a clean Mac for git/build tooling.
xcode-select --install

# 2. Apple Silicon only, if you need Intel-only casks/apps.
softwareupdate --install-rosetta --agree-to-license

# 3. Clone to the expected path. Several configs assume ~/.dotfiles.
git clone --recurse-submodules https://github.com/rensftw/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# 4. Install Homebrew packages, submodules, nvm, Python, and Python packages.
bash install.sh

# 5. Link dotfiles, build nnn, install Node LTS, and sync Neovim plugins.
bash configure.sh

# 6. Optional: apply macOS defaults. This script prompts, then schedules a restart.
bash macos.sh
```

No Git yet? Download with the system `curl`/`tar` instead, then run the same install commands:

```sh
mkdir -p ~/.dotfiles
curl -L https://api.github.com/repos/rensftw/.dotfiles/tarball | tar -xz -C ~/.dotfiles --strip-components=1
cd ~/.dotfiles
bash install.sh
bash configure.sh
```

## Dry-run mode

All top-level scripts support `--dry-run` (or `-n`) to print what would run without changing files:

```sh
cd ~/.dotfiles
bash install.sh --dry-run
bash configure.sh --dry-run
bash backup.sh --dry-run
bash macos.sh --dry-run
bash uninstall.sh --dry-run
```

Use dry-run first on existing machines. `configure.sh --dry-run` also runs `stow -n` previews, so it can reveal symlink conflicts before files are touched.

## Required tools and assumptions

Before `install.sh`:

- macOS with internet access.
- Administrator privileges for Homebrew, casks, `sudo make install`, and `macos.sh` defaults.
- Apple Command Line Tools (`xcode-select --install`).
- Git for the recommended clone path, or `curl` + `tar` for the tarball path.
- Bash to run the scripts (`bash install.sh`, not `sh install.sh`).

Installed by this repo:

- Homebrew, then all formulae/casks from [`_homebrew/Brewfile`](./_homebrew/Brewfile). `install.sh` does not remove packages outside the Brewfile; use `backup.sh` or Homebrew cleanup commands explicitly when needed.
- GNU Stow for symlink management.
- `pyenv` + latest Python, `nvm` + latest Node LTS, Neovim, tmux, fzf, ripgrep, fd, ncurses, and the desktop apps listed in the Brewfile.
- Git submodules/dependencies: tmux TPM and nnn source.

Local/personal assumptions to review before a fresh setup:

- Clone location should be `~/.dotfiles`; zsh and Neovim setup refer to that path.
- [`git/.gitconfig`](./git/.gitconfig) contains a personal Git name, email, and GPG signing key. Change these before stowing on another account.
- [`macos.sh`](./macos.sh) sets the timezone to `Europe/Sofia`, clears default Dock apps, changes Finder/Safari/Dock behavior, and restarts the machine.
- Private state is intentionally not included: GPG keys, SSH keys, Pi auth/session state, API keys, local Obsidian vault contents, and app login state.
- Existing files such as `~/.zshrc`, `~/.gitconfig`, `~/.config/nvim`, or `~/.tmux.conf` can conflict with Stow. Back them up first.

## What each top-level script does

| Script | Purpose |
| --- | --- |
| [`install.sh`](./install.sh) | Installs Homebrew if needed, runs `brew bundle` against `_homebrew/Brewfile`, fetches submodules/dependencies, installs nvm, installs latest Python through pyenv, and installs default Python packages. |
| [`configure.sh`](./configure.sh) | Exports Homebrew paths, stows all packages, builds/installs nnn from source, creates a VeraCrypt CLI symlink when the app exists, installs Node LTS through nvm, and runs a headless Lazy.nvim plugin sync. |
| [`macos.sh`](./macos.sh) | Applies macOS defaults and schedules a restart. Optional and opinionated. |
| [`backup.sh`](./backup.sh) | Refreshes `_homebrew/Brewfile` from installed Homebrew packages and writes global npm packages to `nvm/.nvm/default-packages`. |
| [`uninstall.sh`](./uninstall.sh) | Prompts for an exact `yes`, then removes pyenv/nvm artifacts, unstows dotfiles, uninstalls all Homebrew formulae/casks/taps, and removes Homebrew. Destructive. |

Each top-level script accepts `--dry-run`; action-oriented helper scripts do too and also inherit dry-run mode when called by a top-level script. Shared helper functions such as `run` and `is_dry_run` live in [`_scripts/lib.sh`](./_scripts/lib.sh), which helper scripts source via `$DOTFILES_LOCATION/_scripts/lib.sh`. Helper scripts live in [`_scripts/`](./_scripts) and generally assume they are running from the repo root.

## Repo layout and Stow packages

Directories beginning with `_` are helpers. All other non-hidden top-level directories are Stow packages:

| Package | Main targets |
| --- | --- |
| `aerospace` | `~/.config/aerospace` |
| `alacritty` | `~/.config/alacritty` |
| `bat` | `~/.config/bat` |
| `bin` | `~/.bin` |
| `btop` | `~/.config/btop` |
| `fzf` | `~/.config/fzf` |
| `git` | `~/.gitconfig`; `git/.gitignore` is copied manually by `_scripts/stow.sh` because Stow ignores VCS ignore files. |
| `gnupg` | `~/.gnupg` config only; keys are not included. |
| `neovim` | `~/.config/nvim` |
| `nnn` | `~/.config/nnn` |
| `nvm` | `~/.nvm/default-packages` |
| `pi` | `~/.pi/agent` public-safe Pi config; auth/session state is excluded. |
| `system` | shell aliases, networking notes, truecolor helper, hushlogin |
| `tmux` | `~/.tmux.conf`, `~/.tmux` scripts/plugins |
| `vale` | `~/.vale.ini`, `~/.config/vale`, `~/.vale` styles |
| `vlc` | `~/Library/Preferences/org.videolan.vlc` |
| `zsh` | `~/.zshrc`, `~/.zshenv`, prompt/plugin files |

Full configuration stows every package:

```sh
cd ~/.dotfiles
bash configure.sh
```

Stow-only dry-run examples:

```sh
cd ~/.dotfiles
stow -nvt ~ zsh      # dry run: show what would be linked
stow -vt ~ zsh       # link only zsh files
stow -Dt ~ zsh       # unlink only zsh files
```

## Install and update workflow

Fresh machine:

```sh
cd ~/.dotfiles
bash install.sh --dry-run
bash configure.sh --dry-run
bash install.sh
bash configure.sh
```

Existing machine after pulling changes:

```sh
cd ~/.dotfiles
git pull --recurse-submodules
git submodule update --init --recursive
bash install.sh
bash configure.sh
```

If you want a smaller setup, edit [`_homebrew/Brewfile`](./_homebrew/Brewfile) before `bash install.sh`, and stow only selected packages instead of running `bash configure.sh`.

## macOS setup

Run only after reviewing the file:

```sh
cd ~/.dotfiles
bash macos.sh --dry-run
bash macos.sh
```

Important effects:

- Prompts before doing anything.
- Requests `sudo` and keeps it alive while preferences are applied.
- Changes keyboard, trackpad, Finder, Dock, Safari, Mail, Activity Monitor, power, and security defaults.
- Sets timezone to `Europe/Sofia`.
- Clears default Dock app icons.
- Restarts the computer after one minute.

## Backup

After changing installed Homebrew or global npm packages:

```sh
cd ~/.dotfiles
bash backup.sh --dry-run
bash backup.sh
```

This runs `brew cleanup`, `brew autoremove`, `brew bundle dump --force --file _homebrew/Brewfile`, and writes global npm package names to [`nvm/.nvm/default-packages`](./nvm/.nvm/default-packages).

## Uninstall

```sh
cd ~/.dotfiles
bash uninstall.sh --dry-run
bash uninstall.sh
```

`uninstall.sh` asks you to type `yes`. If accepted, it removes pyenv and nvm artifacts, unstows all packages, uninstalls every Homebrew formula/cask/tap, uninstalls Homebrew, and removes only Homebrew-owned leftover directories. It does not delete the `~/.dotfiles` repo itself or shell history files.

## Troubleshooting

### `brew` is missing after Homebrew install

Open a new shell, or from the repo root run:

```sh
source _scripts/export-brew-variables.sh
```

### Stow reports conflicts

Back up or remove the existing target, then rerun Stow:

```sh
mv ~/.zshrc ~/.zshrc.bak
cd ~/.dotfiles
stow -vt ~ zsh
```

Use `stow -nvt ~ <package>` first to preview changes.

### `configure.sh` cannot build nnn

Make sure dependencies and submodules are present:

```sh
cd ~/.dotfiles
bash install.sh
git submodule update --init --recursive
```

The nnn build needs Homebrew `ncurses`, which is listed in `_homebrew/Brewfile`.

### Neovim plugins did not install

Run the same headless Lazy.nvim sync used by `configure.sh`:

```sh
nvim -u ~/.dotfiles/neovim/.config/nvim/lua/core/lazy.lua --headless "+Lazy! sync" +qa
```

### Git commits fail because of signing

Import the matching GPG key, or edit [`git/.gitconfig`](./git/.gitconfig) and disable/change `commit.gpgsign` and `user.signingkey` before stowing the `git` package.

## Highlights

- Alacritty, tmux + TPM, Neovim, fzf, nnn, AeroSpace, btop, Vale, and VLC configs.
- Neovim uses Lazy.nvim, native LSP, Mason, blink.cmp, LuaSnip, fzf-lua, conform.nvim, nvim-lint, DAP, mini.nvim modules, CodeCompanion, and Tokyonight.
- Shell setup includes zsh, Oh My Posh, fzf defaults, Git helpers, worktree helpers, nvm, pyenv, and GPG agent integration.
