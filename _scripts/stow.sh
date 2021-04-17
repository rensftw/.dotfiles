#!/bin/bash

echo "🐐 ${CYAN}Unpacking dotfiles${NC}"

# Helper directories begin with _ (e.g. _scripts)
HELPER_DIR_PREFIX='_*'

# Store all directory names in an array
directories=($(ls -d */))

# Ignore helper directories when stowing
for dir in "${directories[@]}"; do
    if [[ $dir != $HELPER_DIR_PREFIX ]]; then
        echo "      🔗 ${PURPLE} ${dir%/} ${NC}"
        stow -vt ~ $dir
    fi
done

# Manually copy the global .gitignore as we should avoid linking SVC ignore files
cp ./git/.gitignore ~
