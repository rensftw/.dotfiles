#!/usr/bin/env bash

# Shared dry-run/logging helpers (`run`, `is_dry_run`, etc.).
source "$DOTFILES_LOCATION/_scripts/lib.sh"

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    parse_common_args "$@"
fi

BREWFILE="$DOTFILES_LOCATION/_homebrew/Brewfile"

# Install all taps, formulae, and casks from the Brewfile.
# Do not pass --cleanup here: installing should not remove packages by surprise.
printf "$CYAN$BOLD%s$NORMAL\n"  "📦 Installing Homebrew packages"
run brew bundle install --file "$BREWFILE"

# Verify that the completed bundle matches the curated manifest. Homebrew
# Bundle is built into modern Homebrew and does not need a separate tap.
printf "$CYAN$BOLD%s$NORMAL\n"  "🔎 Verifying Homebrew packages"
run brew bundle check --verbose --file "$BREWFILE"
