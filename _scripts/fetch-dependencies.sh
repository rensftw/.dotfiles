#!/usr/bin/env bash

# If .dotfiles is a git repo itself, add dependencies as git submodules
if [[ -e .git ]]; then
    printf "$CYAN$BOLD%s$NORMAL\n"  "🛢  Unpacking git submodules"

    git submodule init
    git submodule update
else
    # Otherwise, clone each dependency as a normal repo
    printf "$CYAN$BOLD%s$NORMAL\n"  "🚚 Fetching dependencies"

    DOTFILES=$(PWD)

    printf "$CYAN$BOLD%s$NORMAL\n"  "🧲 Cloning tmux package manager"
    mkdir -p "$DOTFILES"/tmux/.tmux/tpm
    git clone https://github.com/tmux-plugins/tpm.git "$DOTFILES"/tmux/.tmux/tpm
fi
