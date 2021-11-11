# If .dotfiles is a git repo itself, add dependencies as git submodules
if [[ -e .git ]]; then
    echo "🛢  ${CYAN}Unpacking git submodules${NC}"

    git submodule init
    git submodule update
else
    # Otherwise, clone each dependency as a normal repo
    echo "🚚 ${CYAN}Fetching dependencies${NC}"

    DOTFILES=$(PWD)

    echo "🧲 engine262"
    mkdir -p $DOTFILES/js-engines/engine262
    git clone https://github.com/engine262/engine262.git $DOTFILES/js-engines/engine262

    echo "🧲 neovim-nightly"
    mkdir -p $DOTFILES/neovim/neovim-nightly
    git clone https://github.com/neovim/neovim.git $DOTFILES/neovim/neovim-nightly
fi
