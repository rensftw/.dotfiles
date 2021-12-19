echo "🔌 ${CYAN}Installing vim plugins${NC}"

nvim --headless +'PackerInstall' +qall > /dev/null
