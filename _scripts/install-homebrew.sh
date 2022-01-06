ARCH=$(arch)

if command -v brew &> /dev/null; then
    echo "☑️  ${GREEN}Homebrew has already been installed${NC}"
else
    echo "🍺 ${CYAN}Installing Homebrew${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Apple Silicon macs do not automatically include Brew in the global PATH
    if [[ $ARCH =~ 'arm' ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi

    # Disable Homebrew analytics (which are on by default)
    brew analytics off
fi
