#!/bin/zsh

source _scripts/colors.sh

echo "${RED}This action is irreversible. Are you sure you want to proceed? (y/n)${NC}"

read ANSWER

if [[ "$ANSWER" == "y" || "$ANSWER" == "yes" ]]; then
    # Ask for sudo and maintain it until all steps are complete
    sh _scripts/ask-for-admin.sh

    # Uninstall all pip packages
    echo "🐍 ${GREEN}Removing pip packages${NC}"
    pip freeze | xargs pip uninstall -y

    # Remove all dotfiles
    sh _scripts/unstow.sh

    # Remove all casks and formulae and then uninstall Homebrew itself
    sh _scripts/uninstall-homebrew.sh

    # Uninstall nvm and all artifacts
    sh _scripts/uninstall-nvm.sh

elif [[ "$ANSWER" == "n" || "$ANSWER" == "no" ]]; then
    echo "${CYAN}No changes made. Quitting..${NC}"
else
    echo "${CYAN}Please type y(es) or n(o).${NC}"
    echo "${CYAN}No changes made. Quitting.."${NC}
    exit

    # Could allow a retry instead of exitting?
    # read SECOND_ANSWER
    # echo "Second answer was: $SECOND_ANSWER"
fi
