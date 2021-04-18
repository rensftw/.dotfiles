# Helper directories begin with _ (e.g. _scripts)
HELPER_DIR_PREFIX='_*'

# Store all directory names in an array
directories=($(ls -d */))

echo "🐐 ${GREEN}Removing stow symlinks${NC}"

# Ignore helper directories when unstowing
for dir in "${directories[@]}"; do
    if [[ $dir != $HELPER_DIR_PREFIX ]]; then
        echo "🔗 Unlinking ${PURPLE}${dir%/}${NC}"
        stow -Dt ~ $dir
    fi
done

