#!/usr/bin/env bash

# Import ANSI escape codes for colors
source _scripts/colors.sh

if [[ -n $HOMEBREW_BUNDLE_FILE ]] && command -v brew &> /dev/null; then
    printf "$GREEN%s$NORMAL\n" "🧼 Clean up Homebrew cache and dangling dependencies"
    # Remove stale lock files and outdated downloads for all formulae and casks, and remove old versions of installed formulae.
    brew cleanup --prune=all
    # Uninstall formulae that were only installed as a dependency of another formula and are now no longer needed.
    brew autoremove

    # Backup Brewfile
    printf "$GREEN%s$NORMAL\n" "📦 Backing up Homebrew packages"
    brew bundle dump --force --file "$HOMEBREW_BUNDLE_FILE"
else
    printf "$RED_BACKGROUND$BOLD%s$NORMAL\n" "❌ Failed to back up Homebrew packages. Cannot find brew."
fi

# Backup global npm packages
if command -v npm &> /dev/null; then
    printf "$GREEN%s$NORMAL\n" "🚀 Backing up global npm packages"
    npm ls -g --parseable | grep 'node_modules' | sed 's/.*node_modules\///' > nvm/.nvm/default-packages
else
    printf "$RED%s$NORMAL\n" "❌ Failed to back up global npm packages. Cannot find npm."
fi
