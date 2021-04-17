echo "🐍 ${CYAN}Installing python packages...${NC}"

PACKAGES=('black' 'flake8')

for package in "${PACKAGES[@]}"; do
    _scripts/revolver start "$package"
    pip install $package > /dev/null
    _scripts/revolver stop
done
