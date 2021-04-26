echo "${CYAN}Setting up VSCode...${NC}"

VSCODE_DIR="$HOME/Library/Application Support/Code/User"

if command -v code &> /dev/null; then
    echo "🧩 ${CYAN}Installing Code extensions${NC}"
    while IFS= read -r extension; do
        _scripts/revolver start "$extension"
        code --install-extension "$extension" --force &> /dev/null
        _scripts/revolver stop
    done < _vscode/vscode-extensions
else
    echo "❌ ${RED}Failed to install Code extensions. Cannot find code CLI.${NC}"
    exit
fi

if [ -d "${VSCODE_DIR}" ]; then
    echo "⚙️  ${CYAN}Adding custom Code settings${NC}"
    ln -fn _vscode/settings.json "$VSCODE_DIR"

    echo "🔑 ${CYAN}Adding custom Code keybindings${NC}"
    ln -fn _vscode/keybindings.json "$VSCODE_DIR"

    echo "⚡️ ${CYAN}Adding custom Code snippets${NC}"
    ln -fn _vscode/custom-snippets.code-snippets "$VSCODE_DIR"/snippets

    if [[ -e _vscode/work.code-snippets ]]; then
        echo "💼 ${CYAN}Adding work-related Code snippets${NC}"
        ln -fn _vscode/work.code-snippets "$VSCODE_DIR"/snippets
    fi
else
    echo "❌ ${RED}Failed to install customizations. Cannot find VSCode application folder.${NC}"
    exit
fi
