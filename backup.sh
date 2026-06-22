#!/usr/bin/env bash
set -Eeuo pipefail

DOTFILES_LOCATION="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_LOCATION
cd "$DOTFILES_LOCATION" || exit 1

# Import ANSI escape codes for colors
source _scripts/colors.sh
source "$DOTFILES_LOCATION/_scripts/lib.sh"
parse_common_args "$@"
enable_error_trap

export HOMEBREW_NO_ANALYTICS=1
HOMEBREW_SNAPSHOT_FILE="${HOMEBREW_SNAPSHOT_FILE:-$DOTFILES_LOCATION/_homebrew/Brewfile.snapshot}"

if ! command -v brew &> /dev/null; then
    source _scripts/export-brew-variables.sh 2>/dev/null || true
fi

if command -v brew &> /dev/null || is_dry_run; then
    # Keep the curated install manifest stable. A snapshot can contain local,
    # work-managed, deprecated, or transitive packages and must be reviewed
    # before anything is merged into _homebrew/Brewfile.
    printf "$GREEN%s$NORMAL\n" "📦 Snapshotting installed Homebrew packages"
    run brew bundle dump --force --file "$HOMEBREW_SNAPSHOT_FILE"
    warn "Review $HOMEBREW_SNAPSHOT_FILE against _homebrew/Brewfile; the curated manifest was not overwritten."
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
