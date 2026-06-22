#!/usr/bin/env bash

# Shared dry-run/logging helpers (`run`, `is_dry_run`, etc.).
source "$DOTFILES_LOCATION/_scripts/lib.sh"

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    parse_common_args "$@"
fi

printf "$GREEN$BOLD%s$NORMAL\n"  "🐍 Removing pyenv artifacts"
rm_rf "$HOME/.pyenv" "$HOME/.pylint.d"
