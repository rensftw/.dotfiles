#!/usr/bin/env bash

# If .dotfiles is a git repo itself, add dependencies as git submodules
if [[ -e .git ]]; then
    echo "🛢  ${CYAN}Unpacking git submodules${NC}"

    git submodule init
    git submodule update
else
    # Otherwise, clone each dependency as a normal repo
    echo "🚚 ${CYAN}Fetching dependencies${NC}"

    DOTFILES=$(PWD)

    echo "🧲 tmux package manager"
    mkdir -p "$DOTFILES"/tmux/.tmux/tpm
    git clone https://github.com/tmux-plugins/tpm.git "$DOTFILES"/tmux/.tmux/tpm
fi
