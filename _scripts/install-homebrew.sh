#!/usr/bin/env bash

ARCH=$(arch)

if command -v brew &> /dev/null; then
    printf "$GREEN$BOLD%s$NORMAL\n"  "✔ Homebrew has already been installed"
else
    printf "$CYAN$BOLD%s$NORMAL\n"  "🍺 Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Manually export brew variables, since dotfiles have not been stowed yet
    source _scripts/export-brew-variables.sh

    # Disable Homebrew analytics (which are on by default)
    brew analytics off
fi
