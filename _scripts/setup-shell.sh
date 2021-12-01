BREW_ZSH_PATH="$(brew --prefix)/bin/zsh"

# Give permissions to zsh (fixes compaudit error)
sudo chmod -R 755 $(brew --prefix)/share/zsh
sudo chmod -R 755 $(brew --prefix)/share/zsh/site-functions

# Modify /etc/shells if the new zsh path is missing
if ! grep -Fqx "$BREW_ZSH_PATH" /etc/shells; then
    echo "🎞 ${CYAN}Adding the zsh path to /etc/shells${NC}"

    echo "$BREW_ZSH_PATH" | sudo tee -a /etc/shells
fi

if [[ $SHELL == $BREW_ZSH_PATH ]]; then
    echo "🐚 ${CYAN}The default shell is $BREW_ZSH_PATH ${NC}"
else
    echo "🐚 ${CYAN}Changing the default shell to $BREW_ZSH_PATH ${NC}"
    # Set default shell for current user
    chsh -s $BREW_ZSH_PATH

    # Set default shell for sudo
    sudo chsh -s $BREW_ZSH_PATH
fi
