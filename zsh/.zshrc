PATH="$(brew --prefix)/share/zsh/site-functions:$PATH"
# curl is keg-only, so we need to manually add  it to our PATH
PATH="$(brew --prefix curl)/bin:$PATH"

export PATH="$HOME:$PATH"

export LC_ALL=en_US.UTF-8
export VISUAL=nvim
export EDITOR="$VISUAL"
export VIMRC_LOCATION="$HOME/.config/nvim/init.vim"
export ZSHRC_LOCATION="$HOME/.zshrc"
export ALIASES_LOCATION="$HOME/.aliases"
export DOTFILES_LOCATION="$HOME/.dotfiles"
export HOMEBREW_BUNDLE_FILE="$HOME/.dotfiles/_homebrew/Brewfile"

source $HOME/.aliases

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

# curl setup
export CURL_CA_BUNDLE="$(brew --prefix ca-certificates)/share/ca-certificates/cacert.pem"

# zsh-completions setup
FPATH=$(brew --prefix)/share/zsh-completions:$FPATH
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
[ -f $HOME/.fzf.zsh ] && source $HOME/.fzf.zsh
export FZF_DEFAULT_OPTS='--multi --inline-info --height 50% --layout=reverse --border'
export FZF_COMPLETION_TRIGGER='~~'
export FZF_DEFAULT_COMMAND="fd --type file --hidden --no-ignore"

# zsh-syntax-highlighting.zsh must be sourced at the end of .zshrc
# (https://github.com/zsh-users/zsh-syntax-highlighting#why-must-zsh-syntax-highlightingzsh-be-sourced-at-the-end-of-the-zshrc-file)
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

