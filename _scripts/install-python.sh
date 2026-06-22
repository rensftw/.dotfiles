#!/usr/bin/env bash

# Shared dry-run/logging helpers (`run`, `is_dry_run`, etc.).
source "$DOTFILES_LOCATION/_scripts/lib.sh"

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    parse_common_args "$@"
fi

printf "$CYAN$BOLD%s$NORMAL\n"  "🐍 Installing latest Python version"

if is_dry_run; then
    run_shell 'eval "$(pyenv init -)"'
    run_shell 'LATEST_PYTHON_VERSION=$(pyenv install --list | grep --extended-regexp "^\s*[0-9][0-9.]*[0-9]\s*$" | tail -1 | tr -d " ")'
    run_shell 'pyenv install -s "$LATEST_PYTHON_VERSION"'
    run_shell 'pyenv global "$LATEST_PYTHON_VERSION"'
    return 0 2>/dev/null || exit 0
fi

if ! command -v pyenv &> /dev/null; then
    printf "$RED_BACKGROUND$BOLD%s$NORMAL\n" "❌ Cannot install Python because pyenv is missing. Run ./install.sh after Homebrew packages are installed."
    exit 1
fi

# Since dotfiles have not been stowed yet, we need to manually init pyenv
eval "$(pyenv init -)"

LATEST_PYTHON_VERSION=$(pyenv install --list | grep --extended-regexp "^\s*[0-9][0-9.]*[0-9]\s*$" | tail -1 | tr -d ' ')
pyenv install -s "$LATEST_PYTHON_VERSION"
pyenv global "$LATEST_PYTHON_VERSION"

printf "$GREEN$BOLD%s$NORMAL\n"  "✔  Installed Python $LATEST_PYTHON_VERSION"
