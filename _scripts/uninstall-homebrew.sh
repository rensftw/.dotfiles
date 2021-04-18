# Uninstall all formulas
echo "${GREEN}Removing all formulae${NC}"
brew uninstall --force --zap $(brew list --formula)

# Uninstall all casks
echo "${GREEN}Removing all casks${NC}"
brew uninstall --force --zap $(brew list --cask)

# Remove all taps
echo "${GREEN}Removing all taps${NC}"
brew untap $(brew tap)

# Uninstall Homebrew itself
echo "${GREEN}Removing Homebrew itself${NC}"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"

echo "${GREEN}Removing leftover artifacts${NC}"
rm -rf /usr/local/Frameworks
rm -rf /usr/local/Homebrew
rm -rf /usr/local/bin
rm -rf /usr/local/etc
rm -rf /usr/local/include
rm -rf /usr/local/lib
rm -rf /usr/local/opt
rm -rf /usr/local/sbin
rm -rf /usr/local/share
rm -rf /usr/local/var
