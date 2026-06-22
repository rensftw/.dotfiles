#!/usr/bin/env bash

# Shared dry-run/logging helpers (`run`, `is_dry_run`, etc.).
source "$DOTFILES_LOCATION/_scripts/lib.sh"

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    parse_common_args "$@"
fi

# Use the same package rule as stow.sh: visible top-level directories without
# an underscore prefix. Globbing keeps the list deterministic and space-safe.
DIRECTORIES=()
for dir in */; do
    dir="${dir%/}"
    [[ "$dir" == _* ]] || DIRECTORIES+=("$dir")
done

printf "$GREEN$BOLD%s$NORMAL\n"  "🐐 Removing stow symlinks"

for dir in "${DIRECTORIES[@]}"; do
    printf "$MAGENTA$BOLD%s$NORMAL\n" "🔗 Unlinking $dir"
    if is_dry_run && command -v stow &> /dev/null; then
        if ! stow -nDt "$HOME" "$dir"; then
            warn "unstow preview found conflicts for $dir"
        fi
    else
        run stow -Dt "$HOME" "$dir"
    fi
done
