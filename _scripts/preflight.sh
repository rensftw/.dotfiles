#!/usr/bin/env bash

source "$DOTFILES_LOCATION/_scripts/lib.sh"

_preflight_missing_command() {
    local command_name="$1"
    local guidance="$2"

    if command -v "$command_name" >/dev/null 2>&1; then
        return 0
    fi

    if is_dry_run; then
        warn "Preflight: '$command_name' is missing. $guidance"
        return 0
    fi

    die "Preflight: '$command_name' is required. $guidance"
}

_preflight_missing_executable() {
    local executable="$1"
    local guidance="$2"

    if [[ -x "$executable" ]]; then
        return 0
    fi

    if is_dry_run; then
        warn "Preflight: '$executable' is unavailable. $guidance"
        return 0
    fi

    die "Preflight: '$executable' is required. $guidance"
}

_preflight_base() {
    local machine_architecture

    if [[ "$(uname -s)" != "Darwin" ]]; then
        die "These setup scripts support macOS only."
    fi

    machine_architecture="$(uname -m)"
    case "$machine_architecture" in
        arm64|x86_64)
            ;;
        *)
            die "Unsupported Mac architecture: $machine_architecture"
            ;;
    esac

    if [[ "$DOTFILES_LOCATION" != "$HOME/.dotfiles" ]]; then
        if is_dry_run; then
            warn "Preflight: repository is at $DOTFILES_LOCATION; shell configuration expects $HOME/.dotfiles."
        else
            die "Clone this repository to $HOME/.dotfiles; shell configuration depends on that path."
        fi
    fi
}

_preflight_install() {
    local available_kilobytes
    local macos_major

    _preflight_missing_command curl "Install the Apple Command Line Tools first."
    _preflight_missing_command git "Run 'xcode-select --install' first."
    _preflight_missing_command xcode-select "Run 'xcode-select --install' first."

    if ! xcode-select -p >/dev/null 2>&1; then
        if is_dry_run; then
            warn "Preflight: Apple Command Line Tools are not selected. Run 'xcode-select --install'."
        else
            die "Apple Command Line Tools are required. Run 'xcode-select --install', finish it, and retry."
        fi
    fi

    macos_major="$(sw_vers -productVersion | cut -d. -f1)"
    if [[ "$macos_major" =~ ^[0-9]+$ ]] && (( macos_major < 14 )); then
        warn "macOS $macos_major is outside Homebrew's current supported macOS range; upgrade macOS before relying on this setup."
    fi

    available_kilobytes="$(df -Pk "$HOME" | awk 'NR == 2 { print $4 }')"
    if [[ "$available_kilobytes" =~ ^[0-9]+$ ]] && (( available_kilobytes < 20971520 )); then
        warn "Less than 20 GiB is free. Homebrew casks, Xcode tools, and source builds may run out of space."
    fi
}

_preflight_configure() {
    _preflight_missing_command brew "Run 'bash install.sh' first."
    _preflight_missing_command git "Install Apple Command Line Tools."
    _preflight_missing_command make "Install Apple Command Line Tools."
    _preflight_missing_command nvim "Run 'bash install.sh' first."
    _preflight_missing_command stow "Run 'bash install.sh' first."
    _preflight_missing_command sudo "Use an administrator-capable macOS account."
    _preflight_missing_command tree-sitter "Run 'bash install.sh' first; Neovim parser setup requires tree-sitter-cli."
    _preflight_missing_command tmux "Run 'bash install.sh' first."
    _preflight_missing_executable \
        "$DOTFILES_LOCATION/tmux/.tmux/tpm/bin/install_plugins" \
        "Run 'bash install.sh' or 'git submodule update --init --recursive' first."
    _preflight_missing_executable \
        "$DOTFILES_LOCATION/tmux/.tmux/tpm/bin/update_plugins" \
        "Run 'bash install.sh' or 'git submodule update --init --recursive' first."

    if [[ ! -s "$HOME/.nvm/nvm.sh" ]]; then
        if is_dry_run; then
            warn "Preflight: nvm is missing from $HOME/.nvm. Run 'bash install.sh' first."
        else
            die "Preflight: nvm is missing from $HOME/.nvm. Run 'bash install.sh' first."
        fi
    fi
}

_preflight_macos() {
    _preflight_missing_command defaults "This command is included with macOS."
    _preflight_missing_command killall "This command is included with macOS."
    _preflight_missing_command pmset "This command is included with macOS."
    _preflight_missing_command sudo "Use an administrator-capable macOS account."
    _preflight_missing_command systemsetup "This command is included with macOS."
    _preflight_missing_executable /usr/bin/fdesetup "This command is included with macOS."
    _preflight_missing_executable /usr/libexec/ApplicationFirewall/socketfilterfw "This command is included with macOS."
}

run_preflight() {
    local phase="$1"

    _preflight_base

    case "$phase" in
        install)
            _preflight_install
            ;;
        configure)
            _preflight_configure
            ;;
        macos)
            _preflight_macos
            ;;
        *)
            die "Unknown preflight phase: $phase"
            ;;
    esac

    printf 'Preflight passed for %s.\n' "$phase"
}
