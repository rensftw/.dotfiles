if command -v nnn &> /dev/null; then
    echo "☑️  ${GREEN}nnn has already been installed${NC}"
else
    DOTFILES=$(PWD)
    NNN_REPO=$DOTFILES/nnn/.config/nnn/nnn-repo

    cd $NNN_REPO
    echo "🗃  ${CYAN}Build nnn${NC}"
    make O_NERD=1

    echo "🔗  ${CYAN}Install nnn and its manpage${NC}"
    sudo make install

    echo "🧰  ${CYAN}Add plugins${NC}"
    curl -Ls https://raw.githubusercontent.com/jarun/nnn/master/plugins/getplugs | sh

    cd $DOTFILES
fi
