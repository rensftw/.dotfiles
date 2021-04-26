FONT_DIR="/Library/Fonts"

echo "🖍 ${CYAN} Add custom fonts${NC}"

# Create the font directory, if it doesn't already exist
if [[ ! -e $FONT_DIR ]]; then
    mkdir -p $FONT_DIR
fi

for file in _fonts/*; do
    echo "Adding ${PURPLE}${file#_fonts/}${NC}"
    cp "$file" $FONT_DIR
done
