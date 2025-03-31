#!/usr/bin/env bash

printf "$CYAN$BOLD%s$NORMAL\n"  "🐍 Installing latest Python version"

# Since dotfiles have not been stowed yet, we need to manually init pyenv
eval "$(pyenv init -)"

LATEST_PYTHON_VERSION=$(pyenv install --list | grep --extended-regexp "^\s*[0-9][0-9.]*[0-9]\s*$" | tail -1 | tr -d ' ')
pyenv install "$LATEST_PYTHON_VERSION"
pyenv global "$LATEST_PYTHON_VERSION"

printf "$GREEN$BOLD%s$NORMAL\n"  "✔  Installed Python $LATEST_PYTHON_VERSION"
