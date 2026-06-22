#!/usr/bin/env bash

# Shared dry-run/logging helpers (`run`, `is_dry_run`, etc.).
source "$DOTFILES_LOCATION/_scripts/lib.sh"

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    parse_common_args "$@"
fi

printf "$CYAN$BOLD%s$NORMAL\n"  "🔌 Installing vim plugins"
LAZY_CONFIG="$HOME/.dotfiles/neovim/.config/nvim/lua/core/lazy.lua"

# Load a bare minimum config (just the Lazy portion) in order
# to avoid errors from configs that depend on external plugins
# (which are not installed yet, at this point)
run nvim -u "$LAZY_CONFIG" --headless "+Lazy! sync" +qa
