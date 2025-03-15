#!/usr/bin/env bash

if command -v nnn &> /dev/null; then
    printf "$GREEN$BOLD%s$NORMAL\n" "✔ nnn has already been installed"
else
    DOTFILES=$(PWD)
    NNN_REPO=$DOTFILES/nnn/.config/nnn/nnn-repo

    cd "$NNN_REPO" || exit
    printf "$CYAN%s$NORMAL\n" "🗃  Build nnn"
    # Remove existing nnn binary (if we have previously compiled it)
    rm ./nnn
    # Build nnn with Nerd font support, remove mouse support
    # Use newer ncurses because the system default ncurses is too old and causes issues 
    # https://github.com/jarun/nnn/wiki/Developer-guides#compile-for-macos
    LDLIBS="-L/opt/homebrew/opt/ncurses/lib/" CPPFLAGS="-I/opt/homebrew/opt/ncurses/include" make O_NERD=1 O_NOMOUSE=1


    printf "$CYAN%s$NORMAL\n" "🔗  Install nnn and its manpage"
    sudo make install

    printf "$CYAN%s$NORMAL\n" "🧰  Add plugins"
    curl -Ls https://raw.githubusercontent.com/jarun/nnn/master/plugins/getplugs | sh

    cd "$DOTFILES" || exit
fi
