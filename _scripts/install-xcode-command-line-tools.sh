if ! command -v xcode-select --version &> /dev/null; then
    echo "🛠 ${CYAN}Installing XCode command line tools${NC}"
    xcode-select --install
    exit
else
    echo "☑️  ${GREEN}Xcode command line tools already installed${NC}"
    exit
fi
