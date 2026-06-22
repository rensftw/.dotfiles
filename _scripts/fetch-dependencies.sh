#!/usr/bin/env bash

# Shared dry-run/logging helpers (`run`, `is_dry_run`, etc.).
source "$DOTFILES_LOCATION/_scripts/lib.sh"

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    parse_common_args "$@"
fi

# If .dotfiles is a git repo itself, add dependencies as git submodules
if [[ -e .git ]]; then
    printf "$CYAN$BOLD%s$NORMAL\n"  "🛢  Unpacking git submodules"

    run git submodule update --init --recursive
else
    # A source archive has no Git metadata, so reproduce the submodules as
    # normal Git checkouts at the exact revisions recorded by this repository.
    printf "$CYAN$BOLD%s$NORMAL\n"  "🚚 Fetching dependencies"

    DOTFILES="$PWD"

    TPM_DIR="$DOTFILES/tmux/.tmux/tpm"
    NNN_REPO="$DOTFILES/nnn/.config/nnn/nnn-repo"
    TPM_REVISION="99469c4a9b1ccf77fade25842dc7bafbc8ce9946"
    NNN_REVISION="3d13c7cb41bc3d7edb78b24eefc555636cd343d9"

    fetch_pinned_dependency() {
        local name="$1"
        local repository="$2"
        local destination="$3"
        local revision="$4"

        if [[ -e "$destination" ]] && ! git -C "$destination" rev-parse --git-dir >/dev/null 2>&1; then
            if is_dry_run; then
                warn "$destination exists but is not a Git checkout. Move it aside before a real install."
                return 0
            fi
            die "$destination exists but is not a Git checkout. Move it aside and retry."
        fi

        if [[ ! -e "$destination" ]]; then
            printf "$CYAN$BOLD%s$NORMAL\n" "🧲 Cloning $name"
            run mkdir -p "$(dirname "$destination")"
            run git clone --filter=blob:none --no-checkout "$repository" "$destination"
        fi

        run git -C "$destination" fetch --depth 1 origin "$revision"
        run git -C "$destination" checkout --detach "$revision"
    }

    fetch_pinned_dependency "tmux package manager" \
        https://github.com/tmux-plugins/tpm.git "$TPM_DIR" "$TPM_REVISION"
    fetch_pinned_dependency "nnn source" \
        https://github.com/jarun/nnn.git "$NNN_REPO" "$NNN_REVISION"
fi
