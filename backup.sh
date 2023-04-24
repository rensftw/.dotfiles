#!/usr/bin/env bash

# Import ANSI escape codes for colors
source _scripts/colors.sh

if [[ -n $HOMEBREW_BUNDLE_FILE ]] && command -v brew &> /dev/null; then
    echo "🧼 ${GREEN}Clean up Homebrew cache and dangling dependencies${NC}"
    # Remove stale lock files and outdated downloads for all formulae and casks, and remove old versions of installed formulae.
    brew cleanup --prune=all
    # Uninstall formulae that were only installed as a dependency of another formula and are now no longer needed.
    brew autoremove

    # Backup Brewfile
    echo "📦 ${GREEN}Backing up Homebrew packages${NC}"
    brew bundle dump --force --file "$HOMEBREW_BUNDLE_FILE"
else
    echo "❌ ${RED}Failed to back up Homebrew packages. Cannot find brew.${NC}"
fi

# Backup global npm packages
if command -v npm &> /dev/null; then
    echo "🚀 ${GREEN}Backing up global npm packages${NC}"
    npm ls -g --parseable | grep 'node_modules' | sed 's/.*node_modules\///' > nvm/.nvm/default-packages
else
    echo "❌ ${RED}Failed to back up global npm packages. Cannot find npm.${NC}"
fi
