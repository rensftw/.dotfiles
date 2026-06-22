#!/usr/bin/env bash

# Shared dry-run/logging helpers (`run`, `is_dry_run`, etc.).
source "$DOTFILES_LOCATION/_scripts/lib.sh"

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    parse_common_args "$@"
fi

# Make sure the brew command is available for both Apple Silicon and Intel Macs.
ARCH=$(arch)
if [[ $ARCH =~ 'arm' ]]; then
    BREW_BIN="/opt/homebrew/bin/brew"
else
    BREW_BIN="/usr/local/bin/brew"
fi

if [[ -x "$BREW_BIN" ]]; then
    eval "$("$BREW_BIN" shellenv)"
elif command -v brew &> /dev/null; then
    eval "$(brew shellenv)"
elif is_dry_run 2>/dev/null; then
    warn "Homebrew is not installed or not on PATH; continuing dry-run."
    return 0 2>/dev/null || exit 0
else
    printf "%s\n" "Homebrew is not installed or not on PATH." >&2
    return 1 2>/dev/null || exit 1
fi
