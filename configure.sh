# Import ANSI escape codes for colors
source _scripts/colors.sh

# Manually export brew variables, since dotfiles have not been stowed yet
source _scripts/export-brew-variables.sh

# Welcome message
source _scripts/welcome.sh

echo "🛠  ${PURPLE}Beginning tool configuration...${NC}"

# Fetch dependencies (as git modules or manually)
source _scripts/fetch-dependencies.sh

# Link dotfiles with stow
source _scripts/stow.sh

# Reload to start using ZSH
source _scripts/setup-shell.sh

# Symlink Veracrypt binary
source _scripts/symlink-veracrypt-binary.sh

# Install the current LTS Node version with the default global packages
source _scripts/install-lts-node.sh

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

