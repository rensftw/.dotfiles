echo "🔌 ${CYAN}Installing vim plugins${NC}"

nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'
