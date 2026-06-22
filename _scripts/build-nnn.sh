#!/usr/bin/env bash

# Shared dry-run/logging helpers (`run`, `is_dry_run`, etc.).
source "$DOTFILES_LOCATION/_scripts/lib.sh"

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    parse_common_args "$@"
fi

NNN_REPO="$DOTFILES_LOCATION/nnn/.config/nnn/nnn-repo"

if command -v nnn &> /dev/null && ! is_dry_run; then
    printf "$GREEN$BOLD%s$NORMAL\n" "✔ nnn has already been installed"
    return 0 2>/dev/null || exit 0
fi

if [[ ! -d "$NNN_REPO" ]]; then
    if is_dry_run; then
        warn "nnn source is missing; the following build is only a preview."
    else
        die "Cannot build nnn because $NNN_REPO is missing. Run 'bash install.sh' first."
    fi
fi

if is_dry_run; then
    NCURSES_PREFIX="${HOMEBREW_PREFIX:-/opt/homebrew}/opt/ncurses"
else
    NCURSES_PREFIX="$(brew --prefix ncurses 2>/dev/null || true)"
    [[ -n "$NCURSES_PREFIX" ]] || die "Cannot build nnn because Homebrew ncurses is missing. Run 'bash install.sh' first."
fi

printf "$CYAN%s$NORMAL\n" "🗃  Building nnn from the pinned submodule"
run rm -f "$NNN_REPO/nnn"
run env LDLIBS="-L$NCURSES_PREFIX/lib/" \
    CPPFLAGS="-I$NCURSES_PREFIX/include" \
    make -C "$NNN_REPO" O_NERD=1 O_NOMOUSE=1

printf "$CYAN%s$NORMAL\n" "🔗  Installing nnn and its manpage"
run sudo make -C "$NNN_REPO" install
