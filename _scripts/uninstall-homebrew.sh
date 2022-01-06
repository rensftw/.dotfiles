if command -v brew &> /dev/null; then
    BREW_PREFIX=$(brew --prefix)

    # Uninstall all formulas
    echo "📊 ${GREEN}Removing all formulae${NC}"
    brew uninstall --force --zap $(brew list --formula)

    # Uninstall all casks
    echo "📟 ${GREEN}Removing all casks${NC}"
    brew uninstall --force --zap $(brew list --cask)

    # Remove all taps
    echo "🚰 ${GREEN}Removing all taps${NC}"
    brew untap $(brew tap)

    # Uninstall Homebrew itself
    echo "🍺 ${GREEN}Removing Homebrew itself${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"

    echo "🧹 ${GREEN}Removing leftover artifacts${NC}"
    sudo rm -rf $BREW_PREFIX/Frameworks
    sudo rm -rf $BREW_PREFIX/Homebrew
    sudo rm -rf $BREW_PREFIX/bin
    sudo rm -rf $BREW_PREFIX/etc
    sudo rm -rf $BREW_PREFIX/include
    sudo rm -rf $BREW_PREFIX/lib
    sudo rm -rf $BREW_PREFIX/opt
    sudo rm -rf $BREW_PREFIX/sbin
    sudo rm -rf $BREW_PREFIX/share
    sudo rm -rf $BREW_PREFIX/var
    sudo rm -rf $HOME/.revolver
    sudo rm -rf $HOME/.gitignore
    sudo rm -rf $HOME/.viminfo
    sudo rm -rf $HOME/.vscode
    sudo rm -rf $HOME/.zcompdump
    sudo rm -rf $HOME/.zsh_history
    sudo rm -rf $HOME/.zsh_sessions
else
    echo "❌ ${RED}Failed to uninstall Homebrew artifacts. Cannot find brew CLI.${NC}"
fi
