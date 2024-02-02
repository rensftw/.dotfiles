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
export OBSIDIAN_LOCATION="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/obsidian"
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
source $(brew --prefix)/share/powerlevel10k/powerlevel10k.zsh-theme
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

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
FZF_DEFAULT_OPTS='--multi --inline-info --height 50% --layout=reverse --border'
# Tokyonight theme
export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS \
--color=fg:#c0caf5,bg:#1a1b26,hl:#ff9e64 \
--color=fg+:#c0caf5,bg+:#292e42,hl+:#ff9e64 \
--color=info:#7aa2f7,prompt:#7dcfff,pointer:#f7768e \
--color=marker:#9ece6a,spinner:#9ece6a,header:#9ece6a"
export FZF_COMPLETION_TRIGGER='~~'
export FZF_DEFAULT_COMMAND="fd --type file --hidden --no-ignore"

# Integration between ZSH+TMUX (needed for dynamic pane titles)
source $DOTFILES_LOCATION/zsh/zsh-titles.plugin.zsh

# zsh-syntax-highlighting.zsh must be sourced at the end of .zshrc
# (https://github.com/zsh-users/zsh-syntax-highlighting#why-must-zsh-syntax-highlightingzsh-be-sourced-at-the-end-of-the-zshrc-file)
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

