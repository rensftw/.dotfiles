#!/usr/bin/env bash
set -Eeuo pipefail

DOTFILES_LOCATION="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_LOCATION
cd "$DOTFILES_LOCATION" || exit 1

# Import ANSI escape codes for colors
source _scripts/colors.sh
source "$DOTFILES_LOCATION/_scripts/lib.sh"
parse_common_args "$@"
enable_error_trap

# A fresh Homebrew install is not on PATH in the next process yet. Export its
# native environment before preflight checks commands installed by Homebrew.
source _scripts/export-brew-variables.sh

source "$DOTFILES_LOCATION/_scripts/preflight.sh"
run_preflight configure

# Welcome message
if ! is_dry_run; then
    source _scripts/welcome.sh
fi

printf "$MAGENTA$BOLD%s$NORMAL\n" "🛠  Beginning tool configuration..."

# Link dotfiles with stow
source _scripts/stow.sh

install_and_update_tmux_plugins() {
    local installer="$HOME/.tmux/tpm/bin/install_plugins"
    local updater="$HOME/.tmux/tpm/bin/update_plugins"
    local output=""
    local status=0

    printf "$CYAN$BOLD%s$NORMAL\n" "🧩 Installing and updating tmux plugins with TPM"

    # TPM reads the declarations from ~/.tmux.conf, keeping one source of
    # truth. The install command clones missing plugins at their current
    # default-branch heads; the update command advances existing checkouts.
    run "$installer"
    if is_dry_run; then
        run "$updater" all
        return 0
    fi

    # TPM backgrounds updates and can exit 0 when an individual git pull
    # failed, so also inspect its per-plugin result lines.
    output="$("$updater" all 2>&1)" || status=$?
    [[ -n "$output" ]] && printf '%s\n' "$output"
    if [[ "$status" -ne 0 ]] || printf '%s\n' "$output" | grep -q '" update fail$'; then
        die "TPM failed to update one or more plugins."
    fi
}

install_and_update_tmux_plugins

# Build and setup nnn
source _scripts/build-nnn.sh

# Copy nnn plugins from the pinned source submodule; never execute a remote
# getplugs script from a moving branch.
source _scripts/install-nnn-plugins.sh

# Symlink Veracrypt binary
source _scripts/symlink-veracrypt-binary.sh

# Install the current LTS Node version with the default global packages
source _scripts/install-lts-node.sh

# Install neovim plugins
source _scripts/install-neovim-plugins.sh

printf "$GREEN$BOLD%s$NORMAL\n"  "🧰 Configuration complete."
if ! is_dry_run; then
    source _scripts/tools-ready.sh
fi
