#!/usr/bin/env bash

# Shared dry-run/logging helpers (`run`, `is_dry_run`, etc.).
source "$DOTFILES_LOCATION/_scripts/lib.sh"

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    parse_common_args "$@"
fi

if command -v nnn &> /dev/null; then
    printf "$GREEN$BOLD%s$NORMAL\n" "✔ nnn has already been installed"
else
    DOTFILES="$PWD"
    NNN_REPO="$DOTFILES/nnn/.config/nnn/nnn-repo"

    if is_dry_run; then
        printf "$CYAN%s$NORMAL\n" "🗃  Build nnn"
        run rm -f "$NNN_REPO/nnn"
        run_shell "cd '$NNN_REPO' && env LDLIBS='-L$(brew --prefix ncurses 2>/dev/null || printf /opt/homebrew/opt/ncurses)/lib/' CPPFLAGS='-I$(brew --prefix ncurses 2>/dev/null || printf /opt/homebrew/opt/ncurses)/include' make O_NERD=1 O_NOMOUSE=1"
        printf "$CYAN%s$NORMAL\n" "🔗  Install nnn and its manpage"
        run_shell "cd '$NNN_REPO' && sudo make install"
        printf "$CYAN%s$NORMAL\n" "🧰  Add plugins"
        run_shell "curl -Ls https://raw.githubusercontent.com/jarun/nnn/master/plugins/getplugs | sh"
        return 0 2>/dev/null || exit 0
    fi

    NCURSES_PREFIX=$(brew --prefix ncurses 2>/dev/null || true)

    if [[ -z "$NCURSES_PREFIX" ]]; then
        printf "$RED_BACKGROUND$BOLD%s$NORMAL\n" "❌ Cannot build nnn because Homebrew ncurses is missing. Run ./install.sh first."
        exit 1
    fi

    if [[ ! -d "$NNN_REPO" ]]; then
        printf "$RED_BACKGROUND$BOLD%s$NORMAL\n" "❌ Cannot build nnn because $NNN_REPO is missing. Run ./install.sh first."
        exit 1
    fi

    cd "$NNN_REPO" || exit
    printf "$CYAN%s$NORMAL\n" "🗃  Build nnn"
    # Remove existing nnn binary (if we have previously compiled it)
    run rm -f ./nnn
    # Build nnn with Nerd font support, remove mouse support.
    # Use Homebrew ncurses because the system default ncurses is too old and causes issues:
    # https://github.com/jarun/nnn/wiki/Developer-guides#compile-for-macos
    run env LDLIBS="-L$NCURSES_PREFIX/lib/" CPPFLAGS="-I$NCURSES_PREFIX/include" make O_NERD=1 O_NOMOUSE=1

    printf "$CYAN%s$NORMAL\n" "🔗  Install nnn and its manpage"
    run sudo make install

    printf "$CYAN%s$NORMAL\n" "🧰  Add plugins"
    run_shell "curl -Ls https://raw.githubusercontent.com/jarun/nnn/master/plugins/getplugs | sh"

    cd "$DOTFILES" || exit
fi
