# Import ANSI escape codes for colors
source _scripts/colors.sh

# Backup Brewfile
if [[ -n $HOMEBREW_BUNDLE_FILE ]] && command -v brew &> /dev/null; then
    echo "📦 ${GREEN}Backing up Homebrew packages${NC}"
    brew bundle dump --force --file $HOMEBREW_BUNDLE_FILE
else
    echo "❌ ${RED}Failed to back up Homebrew packages. Cannot find brew.${NC}"
fi

# Backup Code extensions
if command -v code &> /dev/null; then
    echo "🧩 ${GREEN}Backing up Code extensions${NC}"
    code --list-extensions > _vscode/vscode-extensions
else
    echo "❌ ${RED}Failed to back up Code extensions. Cannot find code CLI.${NC}"
fi

# Backup global npm packages
if command -v npm &> /dev/null; then
    echo "🚀 ${GREEN}Backing up global npm packages${NC}"
    npm ls -g --parseable | grep 'node_modules' | sed 's/.*node_modules\///' > nvm/.nvm/default-packages
else
    echo "❌ ${RED}Failed to back up global npm packages. Cannot find npm.${NC}"
fi
