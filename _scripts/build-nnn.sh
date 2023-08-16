#!/usr/bin/env bash

if command -v nnn &> /dev/null; then
    echo "☑️  ${GREEN}nnn has already been installed${NC}"
else
    DOTFILES=$(PWD)
    NNN_REPO=$DOTFILES/nnn/.config/nnn/nnn-repo

    cd "$NNN_REPO" || exit
    echo "🗃  ${CYAN}Build nnn${NC}"
    # Remove existing nnn binary (if we have previously compiled it)
    rm ./nnn
    # Build nnn with Nerd font support, remove mouse support
    # Use newer ncurses because the system default ncurses is too old and causes issues 
    # https://github.com/jarun/nnn/wiki/Developer-guides#compile-for-macos
    LDLIBS="-L/opt/homebrew/opt/ncurses/lib/" make O_NERD=1 O_NOMOUSE=1


    echo "🔗  ${CYAN}Install nnn and its manpage${NC}"
    sudo make install

    echo "🧰  ${CYAN}Add plugins${NC}"
    curl -Ls https://raw.githubusercontent.com/jarun/nnn/master/plugins/getplugs | sh

    cd "$DOTFILES" || exit
fi
