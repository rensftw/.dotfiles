#!/usr/bin/env bash

printf "$GREEN$BOLD%s$NORMAL\n"  "🚀 Removing NVM"

rm -rf "$HOME"/.nvm
rm -rf "$HOME"/.npm
rm -rf "$HOME"/.bower
