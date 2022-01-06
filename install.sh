# Import ANSI escape codes for colors
source _scripts/colors.sh

echo "🏁 ${PURPLE}Beginning installation...${NC}"

# Install Homebrew
source _scripts/install-homebrew.sh

# Install all packages defined in Brewfile (taps, formulae, casks, and MAS apps)
source _scripts/install-from-brewfile.sh

# Install Node version manager (nvm)
source _scripts/install-nvm.sh

# Install the current LTS Node version with the default global packages
source _scripts/install-lts-node.sh

# Install Python
source _scripts/install-python.sh

# Install Python packages
source _scripts/install-pip-packages.sh

echo "🎉 ${GREEN}Installation complete!${NC}"
source _scripts/goodbye.sh

