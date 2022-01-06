# Import ANSI escape codes for colors
source _scripts/colors.sh

# Welcome message
source _scripts/welcome.sh

echo "🛠  ${PURPLE}Beginning tool configuration...${NC}"

# Fetch dependencies (as git modules or manually)
source _scripts/fetch-dependencies.sh

# Link dotfiles with stow
source _scripts/stow.sh

# Reload to start using ZSH
source _scripts/setup-shell.sh

# Install neovim plugins
source _scripts/install-neovim-plugins.sh

# Set up VSCode (packages, keybindings, settings, custom snippets)
source _scripts/setup-vscode.sh

# Set up iTerm2 (theme + settings)
source _scripts/setup-iterm2.sh

# Set up Rectangle
source _scripts/setup-rectangle.sh

# Set up Dash
source _scripts/setup-dash.sh

echo "🧰 ${GREEN}Configuration complete.${NC}"
source _scripts/tools-ready.sh

