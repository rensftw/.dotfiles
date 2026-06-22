#!/usr/bin/env bash

# Shared dry-run/logging helpers (`run`, `is_dry_run`, etc.).
source "$DOTFILES_LOCATION/_scripts/lib.sh"

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    parse_common_args "$@"
fi

if [[ -s "$HOME/.nvm/nvm.sh" ]] || command -v nvm &> /dev/null; then
    printf "$GREEN$BOLD%s$NORMAL\n"  "✔  NVM has already been installed"
else
    printf "$CYAN$BOLD%s$NORMAL\n"  "🚀 Installing NVM"
    run_shell "curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | zsh > /dev/null"
fi
