echo "🐍 ${CYAN}Installing python packages${NC}"

# Add python binary to the global PATH variable before trying to use pip
export PATH="/usr/local/opt/python/libexec/bin:$PATH"

PACKAGES=('black' 'autopep8' 'flake8' 'pynvim')

for package in "${PACKAGES[@]}"; do
    _scripts/revolver start "$package"
    pip install $package > /dev/null
    _scripts/revolver stop
done
