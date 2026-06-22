#!/usr/bin/env bash

# Shared dry-run/logging helpers (`run`, `is_dry_run`, etc.).
source "$DOTFILES_LOCATION/_scripts/lib.sh"

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    parse_common_args "$@"
fi

PINNED_NVM_VERSION="v0.40.4"
# The rest of this repository and preflight intentionally use ~/.nvm. Do not
# let an inherited NVM_DIR install into a path that zsh will never load.
NVM_DIR="$HOME/.nvm"

if [[ -s "$NVM_DIR/nvm.sh" ]]; then
    if [[ ! -d "$NVM_DIR/.git" ]]; then
        if is_dry_run; then
            warn "NVM exists at $NVM_DIR but is not a Git checkout. A real install would stop; move it aside to install pinned $PINNED_NVM_VERSION."
            return 0 2>/dev/null || exit 0
        fi
        die "NVM exists at $NVM_DIR but is not a Git checkout. Move it aside to install pinned $PINNED_NVM_VERSION."
    fi

    CURRENT_NVM_REVISION="$(git -C "$NVM_DIR" describe --tags --exact-match HEAD 2>/dev/null || true)"
    if [[ "$CURRENT_NVM_REVISION" == "$PINNED_NVM_VERSION" ]]; then
        printf "$GREEN$BOLD%s$NORMAL\n" "✔ NVM $PINNED_NVM_VERSION is installed"
        return 0 2>/dev/null || exit 0
    fi

    printf "$CYAN$BOLD%s$NORMAL\n" "🚀 Updating NVM to $PINNED_NVM_VERSION"
elif [[ -e "$NVM_DIR" ]]; then
    die "$NVM_DIR exists but does not contain nvm.sh. Move it aside and rerun bash install.sh."
else
    printf "$CYAN$BOLD%s$NORMAL\n" "🚀 Installing pinned NVM $PINNED_NVM_VERSION"
    run git clone --filter=blob:none --depth 1 --no-checkout \
        https://github.com/nvm-sh/nvm.git "$NVM_DIR"
fi

# Fetch the annotated release tag explicitly. This avoids Git's confusing
# "tag is not a commit" warning when --branch targets an annotated tag.
run git -C "$NVM_DIR" fetch --depth 1 origin \
    "refs/tags/$PINNED_NVM_VERSION:refs/tags/$PINNED_NVM_VERSION"
run git -C "$NVM_DIR" checkout --detach "$PINNED_NVM_VERSION"

if ! is_dry_run; then
    CURRENT_NVM_REVISION="$(git -C "$NVM_DIR" describe --tags --exact-match HEAD 2>/dev/null || true)"
    [[ "$CURRENT_NVM_REVISION" == "$PINNED_NVM_VERSION" ]] || die "NVM did not resolve to $PINNED_NVM_VERSION."
fi
