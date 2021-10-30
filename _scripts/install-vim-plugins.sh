echo "🔌 ${CYAN}Installing vim plugins${NC}"

# We need to run PlugUpdate! manually, because there is an issue with VimPlug's post-install hook
nvim --headless +'PlugInstall --sync' +'PlugUpdate!' +qall
