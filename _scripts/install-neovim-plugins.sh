#!/usr/bin/env bash

printf "$CYAN$BOLD%s$NORMAL\n"  "🔌 Installing vim plugins"
LAZY_CONFIG="$HOME/.dotfiles/neovim/.config/nvim/lua/core/lazy.lua"

# Load a bare minimum config (just the Lazy portion) in order
# to avoid errors from configs that depend on external plugins
# (which are not installed yet, at this point)
nvim -u "$LAZY_CONFIG" --headless "+Lazy! sync" +qa
