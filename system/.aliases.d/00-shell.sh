#!/usr/bin/env bash
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
    jobs -p | awk '{print $3}' | xargs kill -KILL
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
  nvim -o "$(fzf --no-multi --preview 'bat --color=always {}')"
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

# Daily update: Homebrew + Neovim (lazy non-breaking + Mason + Treesitter) +
# tmux plugins (tpm) plugins. Runs Neovim headlessly — never opens the
# editor. Plugins with breaking changes are skipped and listed for manual review.
#   tend            update everything
#   tend homebrew   update Homebrew only   (alias: brew)
#   tend neovim     update Neovim only     (alias: nvim)
#   tend tmux       update tmux plugins (tpm) only
tend() {
    local do_brew=false do_nvim=false do_tmux=false
    case "${1:-all}" in
        all)           do_brew=true; do_nvim=true; do_tmux=true; do_nnn=true ;;
        homebrew|brew) do_brew=true ;;
        neovim|nvim)   do_nvim=true ;;
        tmux)          do_tmux=true ;;
        *) printf "%susage: tend [homebrew|neovim|tmux|nnn]%s\n" "$YELLOW" "$NC" >&2; return 1 ;;
    esac

    local clean_path="${PATH//$PYENV_ROOT\/shims:/}"   # strip pyenv shims, like the brew alias
    local updater="${DOTFILES_LOCATION:-$HOME/.dotfiles}/_scripts/nvim-update.lua"
    local lol="cat"; command -v lolcat &>/dev/null && lol="lolcat"

    # banner (accent)
    if command -v figlet &>/dev/null; then
        figlet -f ogre "Greetings, earthling!" | $lol
    else
        echo "☀ Greetings, earthling!" | $lol
    fi

    if $do_brew; then
        # Homebrew — run with pyenv shims stripped from PATH (matches the brew alias).
        # Each step echoes the exact command before running it.
        echo ""; figlet -f digital "Homebrew" | $lol
        printf "%s❯ brew update%s\n" "$CYAN" "$NC"
        PATH="$clean_path" command brew update
        printf "%s❯ brew outdated --greedy --verbose%s\n" "$CYAN" "$NC"
        local outdated; outdated="$(PATH="$clean_path" command brew outdated --greedy --verbose)"
        if [[ -n "$outdated" ]]; then
            printf "%s\n" "$outdated" | sed "s/^/  ${GREEN}•${NC} /"
        else
            printf "  %s✔ all up to date%s\n" "$GREEN" "$NC"
        fi
        printf "%s❯ brew upgrade --greedy --no-ask%s\n" "$CYAN" "$NC"
        PATH="$clean_path" command brew upgrade --greedy --no-ask
        printf "%s❯ brew cleanup --prune=all%s\n" "$CYAN" "$NC"
        PATH="$clean_path" command brew cleanup --prune=all
        printf "%s❯ brew autoremove%s\n" "$CYAN" "$NC"
        PATH="$clean_path" command brew autoremove
    fi

    if $do_nvim; then
        # Neovim (headless — never opens the editor; prints its own digital headers)
        if [[ -r "$updater" ]]; then
            nvim --headless -c "luafile $updater" -c "qa!"
        else
            echo ""; printf "  %s✗ updater not found: %s%s\n" "$RED" "$updater" "$NC"
        fi
    fi

    if $do_tmux; then
        # tmux plugins via tpm. update_plugins is CLI-safe — tmux needn't be running.
        echo ""; figlet -f digital "Tmux" | $lol
        local tpm_update="$HOME/.tmux/plugins/tpm/bin/update_plugins"
        if [[ -x "$tpm_update" ]]; then
            printf "%s❯ tpm update_plugins all%s\n" "$CYAN" "$NC"
            "$tpm_update" all
        else
            printf "  %s✗ tpm not found: %s%s\n" "$RED" "$tpm_update" "$NC"
        fi
    fi

    # all done (accent): clover + sign-off
    echo ""
    local clover="${DOTFILES_LOCATION:-$HOME/.dotfiles}/_scripts/clover-ascii.txt"
    [[ -r "$clover" ]] && $lol < "$clover"
    echo "  ✓ all done — have a great day!" | $lol
}
