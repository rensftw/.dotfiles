BREW_ZSH_PATH="/usr/local/bin/zsh"

# Give permissions to zsh (fixes compaudit error)
sudo chmod -R 755 /usr/local/share/zsh
sudo chmod -R 755 /usr/local/share/zsh-completions
sudo chmod -R 755 /usr/local/share/zsh-syntax-highlighting
sudo chmod -R 755 /usr/local/share/zsh/site-functions

# Modify /etc/shells if the new zsh path is missing
if ! grep -Fqx "$BREW_ZSH_PATH" /etc/shells; then
    echo "🎞 ${CYAN}Adding the zsh path to /etc/shells${NC}"

    echo "$BREW_ZSH_PATH" | sudo tee -a /etc/shells
fi

if [[ $SHELL == $BREW_ZSH_PATH ]]; then
    echo "🐚 ${CYAN}The default shell is usr/local/bin/zsh${NC}"
else
    echo "🐚 ${CYAN}Changing the default shell to zsh${NC}"
    # Set default shell for current user
    chsh -s $BREW_ZSH_PATH

    # Set default shell for sudo
    sudo chsh -s $BREW_ZSH_PATH
fi

if [[ $SHELL =~ 'zsh' ]]; then
    echo "🌈 ${CYAN}Applying zsh config${NC}"
    exec zsh &> /dev/null
fi
