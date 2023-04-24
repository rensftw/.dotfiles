# Load Brew binaries before native binaries
PATH="$(brew --prefix)/bin:$PATH"
# Keg-only formulae that I need to manually add to PATH:
PATH="$(brew --prefix fzf)/bin:$PATH"
PATH="$(brew --prefix curl)/bin:$PATH"
PATH="$(brew --prefix lua-language-server)/bin:$PATH"

export PATH="$HOME:$PATH"

export LC_ALL=en_US.UTF-8
export VISUAL="nvim"
export EDITOR="nvim"
export VIMRC_LOCATION="$HOME/.config/nvim/init.lua"
export ZSHRC_LOCATION="$HOME/.zshrc"
export ALIASES_LOCATION="$HOME/.aliases"
export DOTFILES_LOCATION="$HOME/.dotfiles"
export HOMEBREW_BUNDLE_FILE="$HOME/.dotfiles/_homebrew/Brewfile"
export OBSIDIAN_LOCATION="$HOME/Library/Mobile\ Documents/iCloud\~md\~obsidian/Documents/obsidian"
# GPG needs to know TTY to work properly: https://www.gnupg.org/documentation/manuals/gnupg/Invoking-GPG_002dAGENT.html
export GPG_TTY=$(tty)

source $HOME/.config/nnn/.nnnrc.zsh
source $HOME/.aliases

# (Optional) Fix brew warning about ""config" scripts exist outside your system or Homebrew directories"
alias brew='env PATH="${PATH//$(pyenv root)\/shims:/}" brew'

# Prompt setup
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi
source $(brew --prefix)/opt/powerlevel10k/powerlevel10k.zsh-theme
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

HISTFILE=$HOME/.histfile
HISTSIZE=1000
SAVEHIST=1000
setopt autocd beep
unsetopt appendhistory
bindkey -v

# zsh-completions setup
FPATH=$(brew --prefix)/share/zsh-completions:$FPATH
FPATH=$(brew --prefix)/share/zsh/site-functions:$FPATH
# Rust/cargo completions
FPATH=$HOME/.zfunc:$FPATH
zstyle :compinstall filename "$HOME/.zshrc"
zstyle ':completion:*' menu select
zstyle ':completion::complete:git-checkout:argument-rest:remote-branch-refs-noprefix' command "echo"
autoload -Uz compinit
compinit

# nvm setup
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# pyenv setup
eval "$(pyenv init --path)"
eval "$(pyenv init -)"

# FZF configuration
FZF_PREFIX=$(brew --prefix fzf)
# Auto-completion
[[ $- == *i* ]] && source "$FZF_PREFIX/shell/completion.zsh" 2> /dev/null
# Key bindings
source "$FZF_PREFIX/shell/key-bindings.zsh"
# Default flags
export FZF_DEFAULT_OPTS='--multi --inline-info --height 50% --layout=reverse --border'
export FZF_COMPLETION_TRIGGER='~~'
export FZF_DEFAULT_COMMAND="fd --type file --hidden --no-ignore"

# Integration between ZSH+TMUX (needed for dynamic pane titles)
source $DOTFILES_LOCATION/zsh/zsh-titles.plugin.zsh

# zsh-syntax-highlighting.zsh must be sourced at the end of .zshrc
# (https://github.com/zsh-users/zsh-syntax-highlighting#why-must-zsh-syntax-highlightingzsh-be-sourced-at-the-end-of-the-zshrc-file)
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

