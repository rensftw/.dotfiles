echo "🌙 ${CYAN}Building neovim-nightly${NC}"

DOTFILES_DIR="$HOME/.dotfiles"
NEOVIM_NIGHTLY_DIR="$DOTFILES_DIR/neovim/neovim-nightly"

# Got to neovim directory
cd $NEOVIM_NIGHTLY_DIR

# Clean old build (if there is one)
make distclean

# Build Neovim
make CMAKE_BUILD_TYPE=Release

# Install Neovim globally
sudo make install

# Go back to dotfile directory
cd $DOTFILES_DIR
