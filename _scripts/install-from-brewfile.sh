# Install all taps, formulae, and casks from the Brewfile
echo "📦 ${CYAN}Installing Homebrew packages${NC}"

brew bundle install --all --cleanup
