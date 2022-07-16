if command -v veracrypt &> /dev/null; then
    echo "☑️  ${GREEN}Found veracrypt binary${NC}"
else
    echo "🔒 ${CYAN}Symlinking Veracrypt binary${NC}"
    ln -s /Applications/VeraCrypt.app/Contents/MacOS/VeraCrypt /usr/local/bin/veracrypt
    veracrypt --text --version
fi
