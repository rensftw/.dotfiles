ARCH=$(arch)

if command -v brew &> /dev/null; then
    echo "☑️  ${GREEN}Homebrew has already been installed${NC}"
else
    echo "🍺 ${CYAN}Installing Homebrew${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Manually export brew variables, since dotfiles have not been stowed yet
    source _scripts/export-brew-variables.sh

    # Disable Homebrew analytics (which are on by default)
    brew analytics off
fi
