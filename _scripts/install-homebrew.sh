if ! command -v brew &> /dev/null; then
    echo "🍺 ${CYAN}Installing Homebrew${NC}"
    /bin/zsh -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    exit
else
    echo "☑️  ${GREEN}Homebrew has already been installed${NC}"
    exit
fi
