#!/usr/bin/env bash

if command -v veracrypt &> /dev/null; then
    printf "$GREEN$BOLD%s$NORMAL\n"  "✔ Found veracrypt binary"
else
    printf "$CYAN$BOLD%s$NORMAL\n"  "🔒 Symlinking Veracrypt binary"
    ln -s /Applications/VeraCrypt.app/Contents/MacOS/VeraCrypt /usr/local/bin/veracrypt
    veracrypt --text --version
fi
