#!/bin/zsh

# Import ANSI escape codes for colors
source _scripts/colors.sh

echo "This script requires Terminal.app to have full disk access privileges.
To continue grant those permissions via ${PURPLE}Preferences > Security & Privacy > Privacy > Full Disk Access${NC}

"

echo "${YELLOW_BLINK}Proceed? (y/n)${NC}"
read ANSWER

if [[ "$ANSWER" == "y" || "$ANSWER" == "yes" ]]; then
    echo "🏁 ${PURPLE}Beginning installation...${NC}"

    # Install Homebrew
    sh _scripts/install-homebrew.sh

    # Install all packages defined in Brewfile (taps, formulae, casks, and MAS apps)
    sh _scripts/install-from-brewfile.sh

    # Install Node version manager (nvm)
    sh _scripts/install-nvm.sh

    # Install the current LTS Node version with the default global packages
    sh _scripts/install-lts-node.sh

    # Install Python packages
    sh _scripts/install-pip-packages.sh

    echo "🎉 ${GREEN}Installation complete!${NC}"
    sh _scripts/goodbye.sh

    exit
else
    echo "${CYAN}No changes made. Quitting.."${NC}
    exit
fi

