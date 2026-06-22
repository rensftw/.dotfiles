#!/usr/bin/env bash
set -euo pipefail

DOTFILES_LOCATION="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_LOCATION
cd "$DOTFILES_LOCATION" || exit 1

# Import ANSI escape codes for colors
source _scripts/colors.sh
source "$DOTFILES_LOCATION/_scripts/lib.sh"
parse_common_args "$@"

# Manually export brew variables, since dotfiles have not been stowed yet
source _scripts/export-brew-variables.sh

# Welcome message
if ! is_dry_run; then
    source _scripts/welcome.sh
fi

printf "$MAGENTA$BOLD%s$NORMAL\n" "🛠  Beginning tool configuration..."

# Link dotfiles with stow
source _scripts/stow.sh

# Build and setup nnn
source _scripts/build-nnn.sh

# Symlink Veracrypt binary
source _scripts/symlink-veracrypt-binary.sh

# Install the current LTS Node version with the default global packages
source _scripts/install-lts-node.sh

# Install neovim plugins
source _scripts/install-neovim-plugins.sh

printf "$GREEN$BOLD%s$NORMAL\n"  "🧰 Configuration complete."
if ! is_dry_run; then
    source _scripts/tools-ready.sh
fi

