if command -v rustup &> /dev/null; then
    echo "☑️  ${GREEN}rustup has already been installed${NC}"
else
    echo "🦀 ${CYAN}Installing rustup${NC}"
    # Install rustup bypassing the confirmation prompt
    # and not modifying the path, since this is already commited in our .zshenv
    curl https://sh.rustup.rs -sSf | sh -s -- -y --no-modify-path
fi
