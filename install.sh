#!/bin/zsh

# Import ANSI escape codes for colors
source _scripts/colors.sh

echo "This script requires Terminal.app to have full disk access privileges.\nTo continue grant those permissions via Preferences > Security & Privacy > Privacy > Full Disk Access"
echo "${YELLOW_BLINK}Proceed? (y/n)${NC}"
read ANSWER


if [[ "$ANSWER" == "y" || "$ANSWER" == "yes" ]]; then

    echo "🏁 ${PURPLE}Beginning installation...${NC}"

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
else
    echo "${CYAN}No changes made. Quitting.."${NC}
    exit
fi

