#!/usr/bin/env bash
set -euo pipefail

DOTFILES_LOCATION="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_LOCATION
cd "$DOTFILES_LOCATION" || exit 1

# Import ANSI escape codes for colors
source _scripts/colors.sh
source "$DOTFILES_LOCATION/_scripts/lib.sh"
parse_common_args "$@"

printf "$MAGENTA$BOLD%s$NC\n\n" "🏁 Beginning installation..."

# Install Homebrew
source _scripts/install-homebrew.sh

# Install all packages defined in Brewfile (taps, formulae, casks, and MAS apps)
source _scripts/install-from-brewfile.sh

# Fetch dependencies (as git modules or manually)
source _scripts/fetch-dependencies.sh

# Install Node version manager (nvm)
source _scripts/install-nvm.sh

# Install Python
source _scripts/install-python.sh

# Install Python packages
source _scripts/install-pip-packages.sh

printf "$GREEN%s$NC\n" "✔ Installation complete!"
if ! is_dry_run; then
    source _scripts/goodbye.sh
fi

