# Load Brew binaries before native binaries
BREW_PREFIX="$(brew --prefix)"
PATH="$BREW_PREFIX/bin:$PATH"
# Keg-only formulae that I need to manually add to PATH:
PATH="$BREW_PREFIX/opt/fzf/bin:$PATH"
PATH="$BREW_PREFIX/opt/curl/bin:$PATH"
PATH="$BREW_PREFIX/opt/lua-language-server/bin:$PATH"

# Add custom binaries
PATH="$HOME/.local/bin:$PATH" # For Claude Code binary
PATH="$HOME/.bin:$PATH"
export PATH="$HOME:$PATH"

export LC_ALL=en_US.UTF-8
export VISUAL="nvim"
export EDITOR="nvim"
export VIMRC_LOCATION="$HOME/.config/nvim/init.lua"
export ZSHRC_LOCATION="$HOME/.zshrc"
export ALIASES_LOCATION="$HOME/.aliases"
export DOTFILES_LOCATION="$HOME/.dotfiles"
export HOMEBREW_BUNDLE_FILE="$HOME/.dotfiles/_homebrew/Brewfile"
export OBSIDIAN_LOCATION="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/obsidian"

# Only run in interactive shells attached to a real terminal (-t 1):
# while avoiding startup overhead in non-interactive shells/scripts.
if [[ $- == *i* ]] && [[ -t 1 ]]; then
  # GPG and SSH
  # GPG needs to know TTY to work properly:
  # https://www.gnupg.org/documentation/manuals/gnupg/Invoking-GPG_002dAGENT.html
  export GPG_TTY="$(tty)"
  # Launch `gpg-agent` for use by SSH
  gpgconf --launch gpg-agent > /dev/null 2>&1
  gpg-connect-agent updatestartuptty /bye > /dev/null 2>&1
  # Enable SSH to work with GPG
  export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
fi

source $HOME/.config/nnn/.nnnrc.zsh
source $HOME/.aliases

# (Optional) Fix brew warning about ""config" scripts exist outside your system or Homebrew directories"
alias brew='env PATH="${PATH//$PYENV_ROOT\/shims:/}" brew'

# Prompt setup

# Oh My Posh prompt
eval "$(oh-my-posh init zsh --config $DOTFILES_LOCATION/zsh/.omp.toml)"

# # Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# # Initialization code that may require console input (password prompts, [y/n]
# # confirmations, etc.) must go above this block; everything else may go below.
# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi
# source $(brew --prefix)/share/powerlevel10k/powerlevel10k.zsh-theme
# [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# History settings
# Docs: man zshoptions
export HISTFILE="$HOME/.histfile"
export HISTSIZE=1000
export SAVEHIST=1000
setopt autocd                 # if a command isn't valid, but is a directory, cd to that dir
setopt append_history         # append to history file
setopt extended_history       # write the history file in the ':start:elapsed;command' format
unsetopt hist_beep            # don't beep when attempting to access a missing history entry
setopt hist_expire_dups_first # expire a duplicate event first when trimming history
setopt hist_find_no_dups      # don't display a previously found event
setopt hist_ignore_all_dups   # delete an old recorded event if a new event is a duplicate
setopt hist_ignore_dups       # don't record an event that was just recorded again
setopt hist_ignore_space      # don't record an event starting with a space
setopt hist_no_store          # don't store history commands
setopt hist_reduce_blanks     # remove superfluous blanks from each command line being added to the history list
setopt hist_save_no_dups      # don't write a duplicate event to the history file
setopt hist_verify            # don't execute immediately upon history expansion
setopt inc_append_history     # write to the history file immediately, not when the shell exits
unsetopt share_history        # don't share history between all sessions
bindkey -v

# zsh-completions setup
FPATH=$BREW_PREFIX/share/zsh-completions:$FPATH
FPATH=$BREW_PREFIX/share/zsh/site-functions:$FPATH
zstyle :compinstall filename "$HOME/.zshrc"
zstyle ':completion:*' menu select
zstyle ':completion::complete:git-checkout:argument-rest:remote-branch-refs-noprefix' command "echo"
autoload -Uz compinit
# Rebuild completion dump only when it's older than 24 hours; otherwise use cached init.
zcompdump_is_old=(~/.zcompdump(N.mh+24))
if (( ${#zcompdump_is_old} )); then
  compinit
else
  compinit -C
fi

# nvm setup
export NVM_DIR="$HOME/.nvm"
# Put the default node version's bin into PATH at startup.
# This lets claude and other tools find `node` immediately,
# without triggering the full NVM load.
if [[ -s "$NVM_DIR/alias/default" ]]; then
  export PATH="$NVM_DIR/versions/node/$(cat $NVM_DIR/alias/default)/bin:$PATH"
fi

_lazy_load_nvm() {
  # remove wrappers so future calls go direct
   unfunction nvm _lazy_load_nvm 2>/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
}

nvm()  { _lazy_load_nvm; nvm "$@"; }

# pyenv setup (lazy load)
# Keep pyenv shims on PATH immediately so python/pip resolve via pyenv,
# while deferring the heavier `pyenv init` shell integration until first `pyenv` use.
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/shims:$PATH"

_lazy_load_pyenv() {
  # remove wrappers so future calls go direct
  unfunction pyenv _lazy_load_pyenv 2>/dev/null
  eval "$(pyenv init - --no-rehash)"
}

pyenv() { _lazy_load_pyenv; pyenv "$@"; }

# FZF configuration
FZF_PREFIX="$BREW_PREFIX/opt/fzf"
[[ $- == *i* ]] && source "$FZF_PREFIX/shell/completion.zsh" 2> /dev/null
# Key bindings (Ctrl-T, Ctrl-R, Alt-C)
source "$FZF_PREFIX/shell/key-bindings.zsh"
# Default flags live in fzf/.config/fzf/fzfrc (stow-managed).
export FZF_DEFAULT_OPTS_FILE="$HOME/.config/fzf/fzfrc"
export FZF_COMPLETION_TRIGGER='~~'
export FZF_DEFAULT_COMMAND="fd --type file --hidden --no-ignore"

# Integration between ZSH+TMUX (needed for dynamic pane titles)
source $DOTFILES_LOCATION/zsh/zsh-titles.plugin.zsh

# Allow Oh My Posh to detect ZSH vi-mode changes
source $DOTFILES_LOCATION/zsh/zsh-omp-vi-mode.plugin.zsh

# zsh-syntax-highlighting.zsh must be sourced at the end of .zshrc
# (https://github.com/zsh-users/zsh-syntax-highlighting#why-must-zsh-syntax-highlightingzsh-be-sourced-at-the-end-of-the-zshrc-file)
source $BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
