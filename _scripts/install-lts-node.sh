#!/usr/bin/env bash

printf "$CYAN$BOLD%s$NORMAL\n"  "🚀 Installing the current LTS Node with the default global packages"

# Source nvm.sh before using it
source "$HOME"/.nvm/nvm.sh

nvm install --lts
