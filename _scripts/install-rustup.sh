#!/usr/bin/env bash

if command -v rustup &> /dev/null; then
    printf "$GREEN$BOLD%s$NORMAL\n"  "✔  rustup has already been installed"
else
    printf "$CYAN$BOLD%s$NORMAL\n"  "🦀 Installing rustup"
    # Install rustup bypassing the confirmation prompt
    # and not modifying the path, since this is already commited in our .zshenv
    curl https://sh.rustup.rs -sSf | sh -s -- -y --no-modify-path
fi
