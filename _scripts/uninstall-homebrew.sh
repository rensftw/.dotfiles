# Remove all taps
echo "${GREEN}Removing all taps${NC}"
brew untap $(brew tap)

# Uninstall all formulas
echo "${GREEN}Removing all formulae${NC}"
brew uninstall --force --zap $(brew list --formula)

# Uninstall all casks
echo "${GREEN}Removing all casks${NC}"
brew uninstall --force --zap $(brew list --cask)

# Uninstall Homebrew itself
echo "${GREEN}Removing Homebrew itself${NC}"
/bin/zsh -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
