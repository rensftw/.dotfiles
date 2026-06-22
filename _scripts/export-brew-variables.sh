#!/usr/bin/env bash

# Shared dry-run/logging helpers (`run`, `is_dry_run`, etc.).
source "$DOTFILES_LOCATION/_scripts/lib.sh"

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    parse_common_args "$@"
fi

# Prefer an installed native Homebrew instead of the process architecture. This
# remains correct when an Apple Silicon shell is launched through Rosetta.
export HOMEBREW_NO_ANALYTICS=1

if [[ -x /opt/homebrew/bin/brew ]]; then
    BREW_BIN="/opt/homebrew/bin/brew"
elif [[ -x /usr/local/bin/brew ]]; then
    BREW_BIN="/usr/local/bin/brew"
elif command -v brew &> /dev/null; then
    BREW_BIN="$(command -v brew)"
else
    BREW_BIN=""
fi

if [[ -n "$BREW_BIN" && -x "$BREW_BIN" ]]; then
    eval "$("$BREW_BIN" shellenv)"
elif is_dry_run 2>/dev/null; then
    warn "Homebrew is not installed or not on PATH; continuing dry-run."
    return 0 2>/dev/null || exit 0
else
    printf "%s\n" "Homebrew is not installed or not on PATH." >&2
    return 1 2>/dev/null || exit 1
fi
