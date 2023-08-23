#!/usr/bin/env bash

if command -v brew >/dev/null 2>&1; then
    BREW_PREFIX=$(brew --prefix)

    # Uninstall all formulas
    printf "$GREEN$BOLD%s$NORMAL\n"  "📊 Removing all formulae"
    brew uninstall --force --zap "$(brew list --formula)"

    # Uninstall all casks
    printf "$GREEN$BOLD%s$NORMAL\n"  "📟 Removing all casks"
    brew uninstall --force --zap "$(brew list --cask)"

    # Remove all taps
    printf "$GREEN$BOLD%s$NORMAL\n"  "🚰 Removing all taps"
    brew untap "$(brew tap)"

    # Uninstall Homebrew itself
    printf "$GREEN$BOLD%s$NORMAL\n"  "🍺 Removing Homebrew itself"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"

    printf "$GREEN$BOLD%s$NORMAL\n"  "🧹 Removing leftover artifacts"
    sudo rm -rf "$BREW_PREFIX"/Frameworks
    sudo rm -rf "$BREW_PREFIX"/Homebrew
    sudo rm -rf "$BREW_PREFIX"/bin
    sudo rm -rf "$BREW_PREFIX"/etc
    sudo rm -rf "$BREW_PREFIX"/include
    sudo rm -rf "$BREW_PREFIX"/lib
    sudo rm -rf "$BREW_PREFIX"/opt
    sudo rm -rf "$BREW_PREFIX"/sbin
    sudo rm -rf "$BREW_PREFIX"/share
    sudo rm -rf "$BREW_PREFIX"/var
    sudo rm -rf "$HOME"/.revolver
    sudo rm -rf "$HOME"/.gitignore
    sudo rm -rf "$HOME"/.viminfo
    sudo rm -rf "$HOME"/.zcompdump
    sudo rm -rf "$HOME"/.zsh_history
    sudo rm -rf "$HOME"/.zsh_sessions
else
    printf "$RED_BACKGROUND$BOLD%s$NORMAL\n"  "❌ Failed to uninstall Homebrew artifacts. Cannot find brew CLI."
fi
