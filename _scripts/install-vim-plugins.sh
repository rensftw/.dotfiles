echo "🔌 ${CYAN}Installing vim plugins${NC}"

vim -c 'PlugInstall --sync' -c 'qa' > /dev/null
