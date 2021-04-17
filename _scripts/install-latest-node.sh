echo "🚀 ${CYAN}Installing the latest LTS Node with the default global packages${NC}"

# Make sure that nvm is available before using it
source ~/.nvm/nvm.sh

nvm install --lts
