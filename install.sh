#!/bin/zsh

# Export ANSI escape codes for colors
source _scripts/colors.sh

echo "🏁 ${PURPLE}Beginning installation...${NC}"

# Ask for sudo and maintain it until all steps are complete
sh _scripts/ask-for-admin.sh

# Register and fetch git submodules
sh _scripts/unpack-submodules.sh

# Install Xcode command line tools
sh _scripts/install-xcode-command-line-tools.sh

# Install Homebrew
sh _scripts/install-homebrew.sh

# Install all the packages defined in Brewfile (taps, formulae, casks, and MAS apps)
sh _scripts/install-from-brewfile.sh

# Welcome message
sh _scripts/welcome.sh

# Set up nvm
sh _scripts/install-nvm.sh

# Link dotfiles with stow
sh _scripts/stow.sh

# Reload to start using ZSH
sh _scripts/set-up-shell.sh

# Install the lates LTS node with the default global packages
sh _scripts/install-latest-node.sh

# Install Python packages
sh _scripts/install-pip-packages.sh

# Install vim plugins
sh _scripts/install-vim-plugins.sh

# Set up VSCode (packages, keybindings, settings, custom snippets)
sh _scripts/setup-vscode.sh

# Set up iTerm2 (theme + settings)
sh _scripts/setup-iterm2.sh

# add more _scripts, and eventually...
echo "🎉 ${GREEN}Installation complete!${NC}"
sh _scripts/goodbye.sh
