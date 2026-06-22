#!/usr/bin/env bash
set -euo pipefail

DOTFILES_LOCATION="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_LOCATION
cd "$DOTFILES_LOCATION" || exit 1

# Import ANSI escape codes for colors
source _scripts/colors.sh
source "$DOTFILES_LOCATION/_scripts/lib.sh"
parse_common_args "$@"

HOMEBREW_BUNDLE_FILE="${HOMEBREW_BUNDLE_FILE:-$DOTFILES_LOCATION/_homebrew/Brewfile}"

if ! command -v brew &> /dev/null; then
    source _scripts/export-brew-variables.sh 2>/dev/null || true
fi

if command -v brew &> /dev/null || is_dry_run; then
    printf "$GREEN%s$NORMAL\n" "🧼 Clean up Homebrew cache and dangling dependencies"
    # Remove stale lock files and outdated downloads for all formulae and casks, and remove old versions of installed formulae.
    run brew cleanup --prune=all
    # Uninstall formulae that were only installed as a dependency of another formula and are now no longer needed.
    run brew autoremove

    # Backup Brewfile
    printf "$GREEN%s$NORMAL\n" "📦 Backing up Homebrew packages"
    run brew bundle dump --force --file "$HOMEBREW_BUNDLE_FILE"
else
    printf "$RED_BACKGROUND$BOLD%s$NORMAL\n" "❌ Failed to back up Homebrew packages. Cannot find brew."
fi

# Backup global npm packages
if command -v npm &> /dev/null; then
    printf "$GREEN%s$NORMAL\n" "🚀 Backing up global npm packages"
    if is_dry_run; then
        run_shell "npm ls -g --parseable | grep 'node_modules' | sed 's/.*node_modules\\///' > nvm/.nvm/default-packages"
    else
        npm ls -g --parseable | grep 'node_modules' | sed 's/.*node_modules\///' > nvm/.nvm/default-packages || true
    fi
elif is_dry_run; then
    printf "$GREEN%s$NORMAL\n" "🚀 Backing up global npm packages"
    run_shell "npm ls -g --parseable | grep 'node_modules' | sed 's/.*node_modules\\///' > nvm/.nvm/default-packages"
else
    printf "$RED%s$NORMAL\n" "❌ Failed to back up global npm packages. Cannot find npm."
fi
