#!/usr/bin/env bash

if command -v nvm &> /dev/null; then
    printf "$GREEN$BOLD%s$NORMAL\n"  "✔  NVM has already been installed"
else
    printf "$CYAN$BOLD%s$NORMAL\n"  "🚀 Installing NVM"
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | zsh > /dev/null
fi
