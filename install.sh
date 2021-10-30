#!/bin/zsh

# Import ANSI escape codes for colors
source _scripts/colors.sh

echo "🏁 ${PURPLE}Beginning installation...${NC}"

# Ask for sudo and maintain it until all steps are complete
sh _scripts/ask-for-admin.sh

# Install Homebrew
sh _scripts/install-homebrew.sh

# Install all the packages defined in Brewfile (taps, formulae, casks, and MAS apps)
sh _scripts/install-from-brewfile.sh

echo "🎉 ${GREEN}Installation complete!${NC}"
sh _scripts/goodbye.sh

# Restart the session
if [[ $SHELL =~ 'zsh' ]]; then
    exec zsh &> /dev/null
fi
