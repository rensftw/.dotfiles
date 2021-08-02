echo "🌙 ${CYAN}Setting up neovim-nightly${NC}"

NEOVIM_NIGHTLY_DIR="$HOME/.dotfiles/neovim/neovim-nightly"

# Clean old build (if there is one)
make distclean

# Build Neovim
make CMAKE_BUILD_TYPE=Release

# Install Neovim globally
sudo make install
