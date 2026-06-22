#!/usr/bin/env bash

# Shared dry-run/logging helpers (`run`, `is_dry_run`, etc.).
source "$DOTFILES_LOCATION/_scripts/lib.sh"

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    parse_common_args "$@"
fi

# Get Homebrew/bundle before trying to use it
printf "$CYAN$BOLD%s$NORMAL\n"  "🚰 Tapping homebrew/bundle"
run brew tap homebrew/bundle

# Install all taps, formulae, and casks from the Brewfile.
# Do not pass --cleanup here: installing should not remove packages by surprise.
printf "$CYAN$BOLD%s$NORMAL\n"  "📦 Installing Homebrew packages"
run brew bundle install --all --file _homebrew/Brewfile

