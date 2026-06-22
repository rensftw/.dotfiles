#!/usr/bin/env bash

# Shared dry-run/logging helpers (`run`, `is_dry_run`, etc.).
source "$DOTFILES_LOCATION/_scripts/lib.sh"

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    parse_common_args "$@"
fi

printf "$CYAN$BOLD%s$NORMAL\n"  "🐍 Installing python packages"

if is_dry_run; then
    run_shell 'eval "$(pyenv init --path)"'
    run_shell 'eval "$(pyenv init -)"'
else
    if ! command -v pyenv &> /dev/null; then
        printf "$RED_BACKGROUND$BOLD%s$NORMAL\n" "❌ Cannot install Python packages because pyenv is missing."
        exit 1
    fi

    # Add python binary to the global PATH variable before trying to use pip
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
fi

PACKAGES=('black' 'autopep8' 'flake8' 'pynvim')

for package in "${PACKAGES[@]}"; do
    if is_dry_run; then
        run pip install --upgrade "$package"
    else
        _scripts/revolver start "$package"
        pip install --upgrade "$package" > /dev/null
        _scripts/revolver stop
    fi
done
