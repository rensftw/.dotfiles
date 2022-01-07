echo "🔌 ${CYAN}Installing vim plugins${NC}"
PACKER_CONFIG="$HOME/.dotfiles/neovim/.config/nvim/lua/user/packer.lua"

nvim -u $PACKER_CONFIG --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'
