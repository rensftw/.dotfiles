#!/usr/bin/env bash

echo "🔌 ${CYAN}Installing vim plugins${NC}"
PACKER_CONFIG="$HOME/.dotfiles/neovim/.config/nvim/lua/user/packer.lua"

# Load a bare minimum config (just the Packer portion) in order
# to avoid errors from configs that depend on external plugins
# (which are not installed yet, at this point)
nvim -u "$PACKER_CONFIG" --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'
