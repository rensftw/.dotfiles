#!/usr/bin/env bash

# Shared dry-run/logging helpers (`run`, `is_dry_run`, etc.).
source "$DOTFILES_LOCATION/_scripts/lib.sh"

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    parse_common_args "$@"
fi

printf "$CYAN$BOLD%s$NORMAL\n"  "🚀 Installing the current LTS Node with the default global packages"

if is_dry_run; then
    run_shell 'source "$HOME"/.nvm/nvm.sh'
    run nvm install --lts
    return 0 2>/dev/null || exit 0
fi

if [[ ! -s "$HOME/.nvm/nvm.sh" ]]; then
    printf "$RED_BACKGROUND$BOLD%s$NORMAL\n" "❌ Cannot install Node because nvm is missing. Run ./install.sh first."
    exit 1
fi

# Source nvm.sh before using it
source "$HOME"/.nvm/nvm.sh

run nvm install --lts
