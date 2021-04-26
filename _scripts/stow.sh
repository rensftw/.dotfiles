echo "🧹 ${CYAN}Clean default zsh artifacts${NC}"
rm -rf $HOME/.zshrc $HOME/.zshenv $HOME/.zsh $HOME/.zsh_plugins &> /dev/null

# Helper directories begin with an underscore (e.g. _scripts)
HELPER_DIR_PREFIX='_*'

# Store all directory names in an array
DIRECTORIES=($(ls -d */))

# Ignore helper directories when stowing
for dir in "${DIRECTORIES[@]}"; do
    if [[ $dir != $HELPER_DIR_PREFIX ]]; then
        echo "🔗 Linking ${PURPLE}${dir%/}${NC}"
        stow -vt ~ $dir
    fi
done

# Manually copy the global .gitignore as we should avoid linking SVC ignore files
cp ./git/.gitignore ~
