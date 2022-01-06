#!/bin/zsh

source _scripts/colors.sh

echo "${RED}This action is irreversible. Are you sure you want to proceed? (y/n)${NC}"

read ANSWER

if [[ "$ANSWER" == "y" || "$ANSWER" == "yes" ]]; then
    # Remove pyenv artifacts
    source _scripts/uninstall-pyenv.sh

    # Remove all dotfiles
    source _scripts/unstow.sh

    # Remove all casks/taps/formulae and then uninstall Homebrew itself
    source _scripts/uninstall-homebrew.sh

    # Uninstall nvm and all artifacts
    source _scripts/uninstall-nvm.sh
else
    echo "${CYAN}No changes made. Quitting.."${NC}
    exit
fi
