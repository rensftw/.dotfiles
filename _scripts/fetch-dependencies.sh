#!/usr/bin/env bash

# Shared dry-run/logging helpers (`run`, `is_dry_run`, etc.).
source "$DOTFILES_LOCATION/_scripts/lib.sh"

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    parse_common_args "$@"
fi

# If .dotfiles is a git repo itself, add dependencies as git submodules
if [[ -e .git ]]; then
    printf "$CYAN$BOLD%s$NORMAL\n"  "🛢  Unpacking git submodules"

    run git submodule update --init --recursive
else
    # Otherwise, clone each dependency as a normal repo
    printf "$CYAN$BOLD%s$NORMAL\n"  "🚚 Fetching dependencies"

    DOTFILES="$PWD"

    TPM_DIR="$DOTFILES/tmux/.tmux/tpm"
    NNN_REPO="$DOTFILES/nnn/.config/nnn/nnn-repo"

    if [[ -d "$TPM_DIR/.git" ]]; then
        printf "$GREEN$BOLD%s$NORMAL\n"  "✔ tmux package manager has already been fetched"
    elif [[ -e "$TPM_DIR" ]]; then
        warn "Skipping $TPM_DIR because it exists but is not a git repo. Move it aside and retry."
    else
        printf "$CYAN$BOLD%s$NORMAL\n"  "🧲 Cloning tmux package manager"
        run mkdir -p "$(dirname "$TPM_DIR")"
        run git clone https://github.com/tmux-plugins/tpm.git "$TPM_DIR"
    fi

    if [[ -d "$NNN_REPO/.git" ]]; then
        printf "$GREEN$BOLD%s$NORMAL\n"  "✔ nnn source has already been fetched"
    elif [[ -e "$NNN_REPO" ]]; then
        warn "Skipping $NNN_REPO because it exists but is not a git repo. Move it aside and retry."
    else
        printf "$CYAN$BOLD%s$NORMAL\n"  "🧲 Cloning nnn source"
        run mkdir -p "$(dirname "$NNN_REPO")"
        run git clone https://github.com/jarun/nnn.git "$NNN_REPO"
    fi
fi
