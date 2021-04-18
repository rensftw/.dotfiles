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
sudo rm -rf /usr/local/Frameworks
sudo rm -rf /usr/local/Homebrew
sudo rm -rf /usr/local/bin
sudo rm -rf /usr/local/etc
sudo rm -rf /usr/local/include
sudo rm -rf /usr/local/lib
sudo rm -rf /usr/local/opt
sudo rm -rf /usr/local/sbin
sudo rm -rf /usr/local/share
sudo rm -rf /usr/local/var
