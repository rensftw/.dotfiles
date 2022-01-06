if command -v nvm &> /dev/null; then
    echo "☑️  ${GREEN}NVM has already been installed${NC}"
else
    echo "🚀 ${CYAN}Installing NVM${NC}"
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | zsh > /dev/null
fi
