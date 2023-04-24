#!/usr/bin/env bash

echo "🚀 ${CYAN}Installing the current LTS Node with the default global packages${NC}"

# Source nvm.sh before using it
source "$HOME"/.nvm/nvm.sh

nvm install --lts
