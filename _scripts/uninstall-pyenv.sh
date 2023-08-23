#!/usr/bin/env bash

printf "$GREEN$BOLD%s$NORMAL\n"  "🐍 Removing pyenv artifacts"
rm -rf "$HOME"/.pyenv
rm -rf "$HOME"/.pylint.d
