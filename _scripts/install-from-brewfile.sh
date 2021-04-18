echo "🚰 ${CYAN}Tapping homebrew/bundle${NC}"
# Get Homebrew/bundle before trying to use it
brew tap homebrew/bundle

# Install all taps, formulae, and casks from the Brewfile
echo "📦 ${CYAN}Installing Homebrew packages${NC}"
brew bundle install --all --cleanup --file _homebrew/Brewfile
