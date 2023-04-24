#!/usr/bin/env bash

echo "🐍 ${GREEN}Removing pyenv artifacts${NC}"
rm -rf "$HOME"/.pyenv
rm -rf "$HOME"/.pylint.d
