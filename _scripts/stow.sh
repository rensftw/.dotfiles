#!/usr/bin/env bash

# Shared dry-run/logging helpers (`run`, `is_dry_run`, etc.).
source "$DOTFILES_LOCATION/_scripts/lib.sh"

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    parse_common_args "$@"
fi

printf "$CYAN$BOLD%s$NORMAL\n"  "🧹 Checking for existing zsh artifacts"
for path in "$HOME/.zshrc" "$HOME/.zshenv" "$HOME/.zsh" "$HOME/.zsh_plugins"; do
    if [[ -e "$path" && ! -L "$path" ]]; then
        warn "Leaving existing $path in place; stow may report a conflict. Back it up manually if needed."
    fi
done

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
        if is_dry_run && command -v stow &> /dev/null; then
            if ! stow -nvt "$HOME" "$dir"; then
                warn "stow preview found conflicts for $dir"
            fi
        else
            run stow -vt "$HOME" "$dir"
        fi
    fi
done

# Manually copy the global .gitignore as we should avoid linking VCS ignore files.
GITIGNORE_TARGET="$HOME/.gitignore"
if [[ -e "$GITIGNORE_TARGET" ]] && ! cmp -s ./git/.gitignore "$GITIGNORE_TARGET"; then
    warn "Leaving existing $GITIGNORE_TARGET in place; not overwriting it."
elif [[ -e "$GITIGNORE_TARGET" ]]; then
    printf "$GREEN$BOLD%s$NORMAL\n" "✔ $GITIGNORE_TARGET is already up to date"
else
    run cp ./git/.gitignore "$GITIGNORE_TARGET"
fi
