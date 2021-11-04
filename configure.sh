#!/bin/zsh

# Import ANSI escape codes for colors
source _scripts/colors.sh

# Welcome message
sh _scripts/welcome.sh

echo "🛠 ${PURPLE}Beginning tool configuration...${NC}"

# Fetch dependencies (as git modules or manually)
sh _scripts/fetch-dependencies.sh

# Link dotfiles with stow
sh _scripts/stow.sh

# Reload to start using ZSH
sh _scripts/set-up-shell.sh

# Build neovim-nightly
sh _scripts/build-neovim-nightly.sh

# Install neovim plugins
sh _scripts/install-neovim-plugins.sh

# Set up VSCode (packages, keybindings, settings, custom snippets)
sh _scripts/setup-vscode.sh

# Set up iTerm2 (theme + settings)
sh _scripts/setup-iterm2.sh

echo "🧰 ${GREEN}Configuration complete.${NC}"
sh _scripts/tools-ready.sh

