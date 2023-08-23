#!/usr/bin/env bash

printf "$CYAN$BOLD%s$NORMAL\n"  "🧹 Clean default zsh artifacts"
rm -rf "$HOME"/.zshrc "$HOME"/.zshenv "$HOME"/.zsh "$HOME"/.zsh_plugins &> /dev/null

# Helper directories begin with an underscore (e.g. _scripts)
HELPER_DIR_PREFIX='_'

# Store all directory names in an array
# `IFS=`:               sets the internal field separator to an empty string, so that spaces in directory names are preserved.
# `read -r`:            reads a line of input and disables backslash interpretation.
# `-d ''`:              sets the delimiter to the null character, so that directory names with spaces are correctly handled.
# `dir`:                the variable that will hold the directory name.
# `find .`:             searches the current directory and its subdirectories.
# `-maxdepth 1`:        limits the search to the current directory only.
# `-type d`:            searches for directories only.
# `-not -path '*/\.*'`: excludes hidden directories.
# `-not -name '.'`:     excludes the current directory.
# `-print0`:            prints the directory names separated by null characters.
DIRECTORIES=()
while IFS= read -r -d '' dir; do
    STRIPPED_DIRECTORY_NAME=$(basename "$dir")
    DIRECTORIES+=("$STRIPPED_DIRECTORY_NAME")
done < <(find . -maxdepth 1 -type d -not -path '*/\.*' -not -name '.' -print0)

for dir in "${DIRECTORIES[@]}"; do
    # Ignore helper directories when stowing
    if ! [[ "$dir" =~ ^$HELPER_DIR_PREFIX ]]; then
        printf "$MAGENTA%s$NORMAL\n" "🔗 Linking ${dir%/}"
        stow -vt ~ "$dir"
    fi
done

# Manually copy the global .gitignore as we should avoid linking SVC ignore files
cp ./git/.gitignore ~
