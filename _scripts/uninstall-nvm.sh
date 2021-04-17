echo "${GREEN}Removing NVM${NC}"

rm -rf ~/.nvm
rm -rf ~/.npm
rm -rf ~/.bower

echo "${PURPLE}NVM environment variables need to be manually removed from .zshrc${NC}"
