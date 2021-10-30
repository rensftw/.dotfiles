#!/bin/zsh

source _scripts/colors.sh

echo "${RED}This action is irreversible. Are you sure you want to proceed? (y/n)${NC}"

read ANSWER

if [[ "$ANSWER" == "y" || "$ANSWER" == "yes" ]]; then
    # Uninstall all pip packages
    echo "🐍 ${GREEN}Removing pip packages${NC}"
    pip freeze | xargs pip uninstall -y

    # Remove all dotfiles
    sh _scripts/unstow.sh

    # Remove all casks/taps/formulae and then uninstall Homebrew itself
    sh _scripts/uninstall-homebrew.sh

    # Uninstall nvm and all artifacts
    sh _scripts/uninstall-nvm.sh
else
    echo "${CYAN}No changes made. Quitting.."${NC}
    exit
fi
