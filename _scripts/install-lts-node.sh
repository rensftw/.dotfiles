#!/usr/bin/env bash

# Shared dry-run/logging helpers (`run`, `is_dry_run`, etc.).
source "$DOTFILES_LOCATION/_scripts/lib.sh"

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    parse_common_args "$@"
fi

printf "$CYAN$BOLD%s$NORMAL\n"  "🚀 Installing the current LTS Node with the default global packages"
export NVM_DIR="$HOME/.nvm"

if is_dry_run; then
    run_shell 'source "$HOME"/.nvm/nvm.sh'
    run nvm install --lts
    run nvm alias default 'lts/*'
    return 0 2>/dev/null || exit 0
fi

if [[ ! -s "$HOME/.nvm/nvm.sh" ]]; then
    die "Cannot install Node because nvm is missing. Run 'bash install.sh' first."
fi

# nvm's upstream script is not guaranteed to run under errexit, so isolate it
# in a subshell and turn errexit off only for nvm itself.
if ! (
    set +e
    source "$HOME/.nvm/nvm.sh" || exit 1
    nvm install --lts || exit 1
    nvm alias default 'lts/*' || exit 1
    nvm use default || exit 1
    command -v node >/dev/null 2>&1 || exit 1
    command -v npm >/dev/null 2>&1 || exit 1
    node --version || exit 1
    npm --version || exit 1
); then
    die "nvm did not leave a usable current Node LTS release and npm."
fi

# The guarded install above runs in a subshell so nvm cannot disable the
# caller's errexit handling. Activate the verified default again in this shell:
# configure.sh runs Neovim next, and plugin build hooks need npm on PATH.
if ! source "$HOME/.nvm/nvm.sh"; then
    die "nvm installed Node, but its shell environment could not be loaded."
fi
if ! nvm use --silent default; then
    die "nvm installed Node, but the default LTS release could not be activated."
fi
if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
    die "The default Node LTS release is not available to later configuration steps."
fi
