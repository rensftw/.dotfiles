if ! command -v brew &> /dev/null; then
    echo "🍺 ${CYAN}Installing Homebrew${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    #Update to the latest brew version (might help with the bundle subcommand issue?)
    brew update
    exit
else
    echo "☑️  ${GREEN}Homebrew has already been installed${NC}"
    exit
fi
