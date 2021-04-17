#!/bin/zsh

source _scripts/colors.sh

echo "${RED}This action is irreversible. Are you sure you want to proceed? (y/n)${NC}"


read ANSWER

if [[ "$ANSWER" == "y" || "$ANSWER" == "yes" ]]; then
    # Remove all casks and formulae and then uninstall Homebrew itself
    sh _scripts/uninstall-homebrew.sh

    # Uninstall nvm and all artifacts
    sh _scripts/uninstall-nvm.sh

    # Uninstall pip and all packages

    # Remove all dotfiles
    sh _scripts/unstow.sh

    # echo "YAY, answer was: $ANSWER"
elif [[ "$ANSWER" == "n" || "$ANSWER" == "no" ]]; then
    # echo "Oh noes! answer  was negative?! $ANSWER"
    echo "No changes made. Exitting..."
else
    echo "Please type y(es) or n(o)"
    read SECOND_ANSWER
    echo "Second answer was: $SECOND_ANSWER"
fi
