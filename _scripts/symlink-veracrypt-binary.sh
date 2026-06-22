#!/usr/bin/env bash

# Shared dry-run/logging helpers (`run`, `is_dry_run`, etc.).
source "$DOTFILES_LOCATION/_scripts/lib.sh"

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    parse_common_args "$@"
fi

if command -v veracrypt &> /dev/null; then
    printf "$GREEN$BOLD%s$NORMAL\n"  "✔ Found veracrypt binary"
else
    VERACRYPT_APP="/Applications/VeraCrypt.app/Contents/MacOS/VeraCrypt"
    BREW_PREFIX=$(brew --prefix 2>/dev/null || true)

    if [[ ! -x "$VERACRYPT_APP" && ! is_dry_run ]]; then
        printf "$YELLOW$BOLD%s$NORMAL\n" "⚠ VeraCrypt.app was not found; skipping CLI symlink."
        return 0 2>/dev/null || exit 0
    fi

    if [[ -z "$BREW_PREFIX" ]]; then
        if is_dry_run; then
            if [[ $(arch) =~ 'arm' ]]; then
                BREW_PREFIX="/opt/homebrew"
            else
                BREW_PREFIX="/usr/local"
            fi
        else
            printf "$RED_BACKGROUND$BOLD%s$NORMAL\n" "❌ Cannot find Homebrew prefix for VeraCrypt symlink."
            exit 1
        fi
    fi

    printf "$CYAN$BOLD%s$NORMAL\n"  "🔒 Symlinking VeraCrypt binary"
    run mkdir -p "$BREW_PREFIX/bin"
    run ln -sf "$VERACRYPT_APP" "$BREW_PREFIX/bin/veracrypt"
    run veracrypt --text --version
fi
