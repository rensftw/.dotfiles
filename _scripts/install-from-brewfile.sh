# Make sure the brew command is available for 
ARCH=$(arch)
if [[ $ARCH =~ 'arm' ]]; then
    # For Apple Silicon mac
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    # For Intel mac
    eval "$(brew shellenv)"
fi

# Get Homebrew/bundle before trying to use it
echo "🚰 ${CYAN}Tapping homebrew/bundle${NC}"
brew tap homebrew/bundle

# Install all taps, formulae, and casks from the Brewfile
echo "📦 ${CYAN}Installing Homebrew packages${NC}"
brew bundle install --all --cleanup --file _homebrew/Brewfile

