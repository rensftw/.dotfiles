#!/usr/bin/env bash

# Shared dry-run/logging helpers (`run`, `is_dry_run`, etc.).
source "$DOTFILES_LOCATION/_scripts/lib.sh"

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    parse_common_args "$@"
fi

export HOMEBREW_NO_ANALYTICS=1

install_homebrew() {
    local installer
    local status=0

    if is_dry_run; then
        installer="${TMPDIR:-/tmp}/dotfiles-homebrew-install.sh"
        run curl --proto '=https' --tlsv1.2 -fsSLo "$installer" \
            https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
        run /bin/bash "$installer"
        run rm -f "$installer"
        return 0
    fi

    installer="$(mktemp "${TMPDIR:-/tmp}/dotfiles-homebrew.XXXXXX")"
    curl --proto '=https' --tlsv1.2 -fsSLo "$installer" \
        https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh || status=$?
    if (( status == 0 )); then
        /bin/bash "$installer" || status=$?
    fi
    rm -f "$installer"
    return "$status"
}

if command -v brew &> /dev/null; then
    printf "$GREEN$BOLD%s$NORMAL\n"  "✔ Homebrew has already been installed"
else
    printf "$CYAN$BOLD%s$NORMAL\n"  "🍺 Installing Homebrew"
    install_homebrew
fi

# Export Homebrew's environment whether Homebrew was installed just now or was
# already present. This also handles Apple Silicon and Intel without Rosetta
# architecture assumptions.
source "$DOTFILES_LOCATION/_scripts/export-brew-variables.sh"

# Keep the persisted Homebrew preference aligned with the environment opt-out.
run brew analytics off
