#!/usr/bin/env bash

# Import ANSI escape codes for colors
source _scripts/colors.sh

printf "$RED_BACKGROUND%s$NORMAL " "This action is irreversible. Proceed? [y/n]"

read -r ANSWER

if [[ "$ANSWER" == "y" || "$ANSWER" == "yes" ]]; then
    # Remove pyenv artifacts
    source _scripts/uninstall-pyenv.sh

    # Uninstall nvm and all artifacts
    source _scripts/uninstall-nvm.sh

    # Remove all dotfiles
    source _scripts/unstow.sh

    # Remove all casks/taps/formulae and then uninstall Homebrew itself
    source _scripts/uninstall-homebrew.sh
else
    printf "$CYAN%s$NORMAL\n" "No changes made. Quitting.."
fi
