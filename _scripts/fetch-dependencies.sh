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

    echo "🧲 zsh-syntax-highlighting"
    mkdir -p $DOTFILES/zsh/.zsh/zsh-syntax-highlighting
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $DOTFILES/zsh/.zsh/zsh-syntax-highlighting

    echo "🧲 zsh-completions"
    mkdir -p $DOTFILES/zsh/.zsh/zsh-completions
    git clone https://github.com/zsh-users/zsh-completions.git $DOTFILES/zsh/.zsh/zsh-completions

    echo "🧲 powerlevel10k"
    mkdir -p $DOTFILES/zsh/.zsh/powerlevel10k
    git clone https://github.com/romkatv/powerlevel10k.git $DOTFILES/zsh/.zsh/powerlevel10k
fi
