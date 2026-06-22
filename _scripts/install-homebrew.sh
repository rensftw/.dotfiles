#!/usr/bin/env bash

# Shared dry-run/logging helpers (`run`, `is_dry_run`, etc.).
source "$DOTFILES_LOCATION/_scripts/lib.sh"

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    parse_common_args "$@"
fi

if command -v brew &> /dev/null; then
    printf "$GREEN$BOLD%s$NORMAL\n"  "✔ Homebrew has already been installed"
else
    printf "$CYAN$BOLD%s$NORMAL\n"  "🍺 Installing Homebrew"
    if is_dry_run; then
        run_shell '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    else
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Manually export brew variables, since dotfiles have not been stowed yet
        source _scripts/export-brew-variables.sh

        # Disable Homebrew analytics (which are on by default)
        run brew analytics off
    fi
fi
