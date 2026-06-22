#!/usr/bin/env bash

# Shared dry-run/logging helpers (`run`, `is_dry_run`, etc.).
source "$DOTFILES_LOCATION/_scripts/lib.sh"

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    parse_common_args "$@"
fi

if command -v brew >/dev/null 2>&1; then
    BREW_PREFIX=$(brew --prefix)
elif is_dry_run; then
    if [[ $(arch) =~ 'arm' ]]; then
        BREW_PREFIX="/opt/homebrew"
    else
        BREW_PREFIX="/usr/local"
    fi
    warn "Cannot find brew; using $BREW_PREFIX for dry-run preview."
else
    printf "$RED_BACKGROUND$BOLD%s$NORMAL\n"  "❌ Failed to uninstall Homebrew artifacts. Cannot find brew CLI."
    return 0 2>/dev/null || exit 0
fi

guard_brew_prefix "$BREW_PREFIX"

# Uninstall all formulae
printf "$GREEN$BOLD%s$NORMAL\n"  "📊 Removing all formulae"
if command -v brew >/dev/null 2>&1; then
    FORMULAE=($(brew list --formula 2>/dev/null || true))
else
    FORMULAE=()
    run brew list --formula
fi
if (( ${#FORMULAE[@]} )); then
    run brew uninstall --force --zap "${FORMULAE[@]}"
else
    printf "$GREEN$BOLD%s$NORMAL\n" "✔ No formulae to remove"
fi

# Uninstall all casks
printf "$GREEN$BOLD%s$NORMAL\n"  "📟 Removing all casks"
if command -v brew >/dev/null 2>&1; then
    CASKS=($(brew list --cask 2>/dev/null || true))
else
    CASKS=()
    run brew list --cask
fi
if (( ${#CASKS[@]} )); then
    run brew uninstall --force --zap "${CASKS[@]}"
else
    printf "$GREEN$BOLD%s$NORMAL\n" "✔ No casks to remove"
fi

# Remove all taps
printf "$GREEN$BOLD%s$NORMAL\n"  "🚰 Removing all taps"
if command -v brew >/dev/null 2>&1; then
    TAPS=($(brew tap 2>/dev/null || true))
else
    TAPS=()
    run brew tap
fi
if (( ${#TAPS[@]} )); then
    run brew untap "${TAPS[@]}"
else
    printf "$GREEN$BOLD%s$NORMAL\n" "✔ No taps to remove"
fi

# Uninstall Homebrew itself
printf "$GREEN$BOLD%s$NORMAL\n"  "🍺 Removing Homebrew itself"
run_shell '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"'

printf "$GREEN$BOLD%s$NORMAL\n"  "🧹 Removing Homebrew-owned leftovers"
rm_rf "$BREW_PREFIX/Frameworks" "$BREW_PREFIX/Homebrew"

warn "Not removing broad paths such as $BREW_PREFIX/bin or shell history files; remove leftovers manually if needed."
