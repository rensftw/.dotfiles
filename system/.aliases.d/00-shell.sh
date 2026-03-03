################################################################################
# Shell aliases and general utilities
################################################################################

# Navigation aliases
alias ls="ls -G"
if command -v eza &> /dev/null
then
    alias ll="eza \
        --all \
        --long \
        --icons=always \
        --header \
        --modified \
        --time-style=relative \
        --context \
        --mounts \
        --no-user \
        --no-git \
        "
else
    alias ll='ls -Ghal'
fi
alias grep="grep --color=auto"
alias mkdir="mkdir -pv"
alias path='echo -e ${PATH//:/\\n}'
alias c="clear"
alias x="clear; tmux clear-history"
alias df='cd $DOTFILES_LOCATION'
alias av='nvim $VIMRC_LOCATION'
alias az='nvim $ZSHRC_LOCATION'
alias aa='nvim $ALIASES_LOCATION'
alias obsidian='cd $OBSIDIAN_LOCATION && nvim .'

# Use neovim by default
alias vi="nvim"
alias v="nvim"
alias vs="nvim -S"      # open neovim with session

# NNN
alias n="nnn"

# tmux
alias tl="tmux ls"
alias ta="tmux attach"
alias tK="tmux kill-server"
tk() {
    for s in $(tmux list-sessions | awk '{print $1}' | rg ':' -r '' | fzf); do
        tmux kill-session -t "$s"
    done
}

# Kill background processes (like suspended jobs)
kill-bg() {
    jobs -p | xargs kill -KILL
}

# System information
alias si="macchina"

# Restart gpg agent
alias restart-gpg="gpg-connect-agent /bye; gpg-connect-agent killagent /bye; gpgconf --kill gpg-agent; gpg-connect-agent updatestartuptty /bye;"

# Colorize the output of tree
alias tree="tree -C"

# Add syntax highlighting for man pages
man() {
  env \
    LESS_TERMCAP_md="$(tput bold; tput setaf 4)" \
    LESS_TERMCAP_me="$(tput sgr0)" \
    LESS_TERMCAP_mb="$(tput blink)" \
    LESS_TERMCAP_us="$(tput setaf 2)" \
    LESS_TERMCAP_ue="$(tput sgr0)" \
    LESS_TERMCAP_so="$(tput smso)" \
    LESS_TERMCAP_se="$(tput rmso)" \
    PAGER="${commands[less]:-$PAGER}" \
    man "$@"
}


# Find-in-file  (using ripgrep for searching and FZF for previews)
# usage: fif <searchTerm>
fif() {
  if [ ! "$#" -gt 0 ]; then echo "Need a string to search for!"; return 1; fi
  rg --files-with-matches --no-messages "$1" | fzf --preview "highlight -O ansi -l {} 2> /dev/null | rg --colors 'match:bg:yellow' --ignore-case --pretty --context 10 '$1' || rg --ignore-case --pretty --context 10 '$1' {}"
}

# Preview files and open the chosen files in nvim
vf() {
  nvim -o "$(fzf --preview 'bat --color=always {}')"
}

# Process monitoring
alias bt="btop"

# Show active IP ports
alias ap="sudo lsof -i -P -n | grep LISTEN"

# Update to the latest macOS and fetch the full installer
alias fetch-macos-installer="softwareupdate --fetch-full-installer"

# Shows the external IP address and whois information. Useful over VPNs.
external-ip() {
    local IP
    IP=$(curl -s ifconfig.me)

    whois "$IP"
    echo "Your external IP is: ${GREEN}${IP}${NC}"
}

# List all homebrew leaves and their dependencies
# Source: https://stackoverflow.com/questions/41029842/easy-way-to-have-homebrew-list-all-package-dependencies
# Sample output:
# awscli: gdbm readline sqlite tcl-tk xz
bl() {
    brew leaves | xargs brew deps --installed --for-each | sed "s/^.*:/$(tput setaf 4)&$(tput sgr0)/"
}
