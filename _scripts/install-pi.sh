#!/usr/bin/env bash
# Shared dry-run/logging helpers (`run`, `is_dry_run`, etc.).
source "$DOTFILES_LOCATION/_scripts/lib.sh"

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    parse_common_args "$@"
fi

PI_AGENT_DIR="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
PI_MANAGED_ROOT="${PI_MANAGED_INSTALL_ROOT:-${PI_AGENT_DIR%/}/install}"
PI_MANAGED_ROOT="${PI_MANAGED_ROOT%/}"
PI_MANAGED_MARKER="$PI_MANAGED_ROOT/managed-install.json"
PI_MANAGED_LAUNCHER="${PI_MANAGED_ROOT%/*}/bin/pi"

printf "$CYAN$BOLD%s$NORMAL\n" "🥧 Installing managed Pi"

# A valid managed installation always has both the install marker and the
# stable launcher. Updates belong to `pi update` (via `tend pi`), so configure
# does not reinstall an already working release.
if [[ -f "$PI_MANAGED_MARKER" && -x "$PI_MANAGED_LAUNCHER" ]]; then
    if is_dry_run; then
        printf "$GREEN$BOLD%s$NORMAL\n" "✔ Managed Pi is installed"
        return 0 2>/dev/null || exit 0
    fi

    if PI_INSTALLED_VERSION="$("$PI_MANAGED_LAUNCHER" --version)"; then
        printf "$GREEN$BOLD%s$NORMAL\n" "✔ Managed Pi $PI_INSTALLED_VERSION is installed"
        return 0 2>/dev/null || exit 0
    fi
    warn "The managed Pi launcher could not run; invoking the official installer to repair it."
fi

# Keep the managed entrypoint in the user-local bin directory already loaded by
# zsh. Pi stores its stable launcher and pinned releases under ~/.pi/agent.
run mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"
unset PI_LEGACY_INSTALL

# Keep the install/reinstall confirmation interactive, but prevent the official
# installer from launching Pi instead of returning to the rest of configure.sh.
# Its launch prompt is disabled when stdout is not a TTY.
run_shell 'curl -fsSL https://pi.dev/install.sh | /bin/sh | cat'

if is_dry_run; then
    return 0 2>/dev/null || exit 0
fi

if [[ ! -f "$PI_MANAGED_MARKER" || ! -x "$PI_MANAGED_LAUNCHER" ]]; then
    die "Pi's installer completed without creating the expected managed installation at $PI_MANAGED_ROOT."
fi

PI_INSTALLED_VERSION="$("$PI_MANAGED_LAUNCHER" --version)" || \
    die "Managed Pi was installed, but its launcher could not run."
printf "$GREEN$BOLD%s$NORMAL\n" "✔ Installed managed Pi $PI_INSTALLED_VERSION"
