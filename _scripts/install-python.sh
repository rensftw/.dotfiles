echo "🐍 ${CYAN}Installing python 3.9.7${NC}"

# Since dotfiles have not been stowed yet, we need to manually init pyenv
eval "$(pyenv init -)"

pyenv install 3.9.7
pyenv global 3.9.7
