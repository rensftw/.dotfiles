#!/usr/bin/env bash

# Import ANSI escape codes for colors
source _scripts/colors.sh

printf "$MAGENTA$BOLD%s$NC\n\n" "🏁 Beginning installation..."

# Install Homebrew
source _scripts/install-homebrew.sh

# Install all packages defined in Brewfile (taps, formulae, casks, and MAS apps)
source _scripts/install-from-brewfile.sh

# Fetch dependencies (as git modules or manually)
source _scripts/fetch-dependencies.sh

# Install Node version manager (nvm)
source _scripts/install-nvm.sh

# Install Python
source _scripts/install-python.sh

# Install Python packages
source _scripts/install-pip-packages.sh

# Install Rust
source _scripts/install-rustup.sh

printf "$GREEN%s$NC\n" "✔ Installation complete!"
source _scripts/goodbye.sh

