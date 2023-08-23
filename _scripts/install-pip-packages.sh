#!/usr/bin/env bash

printf "$CYAN$BOLD%s$NORMAL\n"  "🐍 Installing python packages"

# Add python binary to the global PATH variable before trying to use pip
eval "$(pyenv init --path)"
eval "$(pyenv init -)"

PACKAGES=('black' 'autopep8' 'flake8' 'pynvim')

for package in "${PACKAGES[@]}"; do
    _scripts/revolver start "$package"
    pip install "$package" > /dev/null
    _scripts/revolver stop
done
