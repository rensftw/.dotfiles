PATH="/usr/local/sbin:$PATH"
PATH="/usr/local/bin:$PATH"
PATH="/usr/local/opt/python/libexec/bin:$PATH"
PATH="$HOME/.zsh_plugins/pure:$PATH"
PATH="/usr/local/share/zsh/site-functions:$PATH"
PATH="/usr/local/opt/curl/bin:$PATH"
export PATH="$HOME:$PATH"

fpath+=$HOME/.zsh/pure

export LC_ALL=en_US.UTF-8
export VIMRC_LOCATION="$HOME/.vimrc"
export ZSHRC_LOCATION="$HOME/.zshrc"
export HOMEBREW_BUNDLE_FILE="$HOME/.dotfiles/_homebrew/Brewfile"

source $HOME/.aliases

# Prompt setup
autoload -U promptinit; promptinit
prompt pure

HISTFILE=$HOME/.histfile
HISTSIZE=1000
SAVEHIST=1000
setopt autocd beep
unsetopt appendhistory
bindkey -v

# Set up zsh-completions
fpath+=$HOME/.zsh/zsh-completions/src
zstyle :compinstall filename '/Users/rensftw/.zshrc'
zstyle ':completion:*' menu select
zstyle ':completion::complete:git-checkout:argument-rest:remote-branch-refs-noprefix' command "echo"

autoload -Uz compinit
compinit

# nvm setup
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# FZF configuration
[ -f $HOME/.fzf.zsh ] && source $HOME/.fzf.zsh
export FZF_DEFAULT_OPTS='--multi --inline-info --height 50% --layout=reverse --border'
export FZF_COMPLETION_TRIGGER='~~'
export FZF_DEFAULT_COMMAND="rg --files --hidden --follow --glob '!.git'"

# zsh-syntax-highlighting.zsh must be sourced at the end of .zshrc
# (https://github.com/zsh-users/zsh-syntax-highlighting#why-must-zsh-syntax-highlightingzsh-be-sourced-at-the-end-of-the-zshrc-file)
source $HOME/.zsh/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
