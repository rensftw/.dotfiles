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

# Setup neovim-nightly
sh _scripts/setup-neovim-nightly.sh

# Install (neo)vim plugins
sh _scripts/install-vim-plugins.sh

# Install Node version manager (nvm)
sh _scripts/install-nvm.sh

# Install the current LTS Node version with the default global packages
sh _scripts/install-latest-node.sh

# Install Python packages
sh _scripts/install-pip-packages.sh

# Set up VSCode (packages, keybindings, settings, custom snippets)
sh _scripts/setup-vscode.sh

# Set up iTerm2 (theme + settings)
sh _scripts/setup-iterm2.sh
