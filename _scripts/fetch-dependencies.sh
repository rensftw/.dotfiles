if [[ -e .git ]]; then
    echo "🛢  ${CYAN}Unpacking git submodules${NC}"

    git submodule init
    git submodule update
else
    echo "🚚 ${CYAN}Fetching dependencies${NC}"

    DOTFILES=$(PWD)

    _scripts/revolver start "engine262"
    mkdir -p $DOTFILES/js-engines/engine262
    cd $DOTFILES/js-engines/engine262
    curl -L https://api.github.com/repos/engine262/engine262/tarball | tar xz --strip=1 &> /dev/null

    _scripts/revolver update "zsh-syntax-highlighting"
    mkdir -p $DOTFILES/zsh/.zsh/zsh-syntax-highlighting
    cd $DOTFILES/zsh/.zsh/zsh-syntax-highlighting
    curl -L https://api.github.com/repos/zsh-users/zsh-syntax-highlighting/tarball | tar xz --strip=1 &> /dev/null

    _scripts/revolver update "zsh-completions"
    mkdir -p $DOTFILES/zsh/.zsh/zsh-completions
    cd $DOTFILES/zsh/.zsh/zsh-completions
    curl -L https://api.github.com/repos/zsh-users/zsh-completions/tarball | tar xz --strip=1 &> /dev/null

    _scripts/revolver update "powerlevel10k"
    mkdir -p $DOTFILES/zsh/.zsh/powerlevel10k
    cd $DOTFILES/zsh/.zsh/powerlevel10k
    curl -L https://api.github.com/repos/romkatv/powerlevel10k/tarball | tar xz --strip=1 &> /dev/null

    _scripts/revolver stop
fi
