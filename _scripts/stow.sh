#!/usr/bin/env bash

# Shared dry-run/logging helpers (`run`, `is_dry_run`, etc.).
source "$DOTFILES_LOCATION/_scripts/lib.sh"

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    parse_common_args "$@"
fi

ensure_real_home_directory() {
    local path="$1"
    local mode="$2"
    local purpose="$3"

    if [[ -L "$path" ]]; then
        if is_dry_run; then
            warn "$path is currently a symlink. Before a real configure run, back it up, remove only the symlink, and create a real directory for $purpose."
            return 0
        fi
        die "$path is a symlink. Back it up, remove only the symlink, and rerun; $purpose must remain outside the dotfiles repository."
    fi

    if [[ -e "$path" && ! -d "$path" ]]; then
        die "$path exists but is not a directory. Move it aside and rerun."
    fi

    run mkdir -p "$path"
    run chmod "$mode" "$path"
}

printf "$CYAN$BOLD%s$NORMAL\n" "🔐 Preparing private and runtime directories"
# Pre-creating these directories prevents GNU Stow from folding the complete
# directory into the repository. Private keys, auth state, plugins, sessions,
# and caches then remain in HOME while only reviewed config files are linked.
ensure_real_home_directory "$HOME/.gnupg" 700 "GnuPG private keys and trust state"
ensure_real_home_directory "$HOME/.tmux" 700 "tmux plugins and resurrect state"
ensure_real_home_directory "$HOME/.nvm" 755 "installed Node versions"
ensure_real_home_directory "$HOME/.pi" 700 "Pi authentication and session state"
ensure_real_home_directory "$HOME/.pi/agent" 700 "Pi authentication and session state"
ensure_real_home_directory "$HOME/.config/nvim" 755 "Neovim configuration"
ensure_real_home_directory "$HOME/.config/nnn" 755 "nnn plugins and session state"

printf "$CYAN$BOLD%s$NORMAL\n"  "🧹 Checking for existing zsh artifacts"
for path in "$HOME/.zshrc" "$HOME/.zshenv" "$HOME/.zsh" "$HOME/.zsh_plugins"; do
    if [[ -e "$path" && ! -L "$path" ]]; then
        warn "Leaving existing $path in place; stow may report a conflict. Back it up manually if needed."
    fi
done

# Every visible top-level directory without an underscore prefix is a Stow
# package. A shell glob is deterministic and preserves spaces in pathnames.
DIRECTORIES=()
for dir in */; do
    dir="${dir%/}"
    [[ "$dir" == _* ]] || DIRECTORIES+=("$dir")
done

# Git ignore rules prevent accidental commits, but Stow does not consult them.
# These explicit rules keep private/runtime state out of HOME symlinks even when
# such files already exist in a developer's working copy.
STOW_IGNORE_ARGUMENTS=(
    "--ignore=^\\.gnupg/(?!gpg-agent\\.conf$|gpg\\.conf$|scdaemon\\.conf$)"
    "--ignore=^\\.tmux/(plugins|resurrect)(/|$)"
    "--ignore=^\\.config/nnn/(plugins|sessions|\\.lastd)(/|$)"
    "--ignore=^\\.config/nvim/\\.netrwhist$"
    "--ignore=^\\.config/nvim/nvim\\.log$"
    "--ignore=^\\.pi/agent/(auth\\.json|sessions)(/|$)"
)

for dir in "${DIRECTORIES[@]}"; do
    printf "$MAGENTA%s$NORMAL\n" "🔗 Will link ${dir%/}"
done

# Check every package before linking the first one, avoiding a partially-stowed
# home directory when a later package has a conflict.
if command -v stow &> /dev/null; then
    if ! stow -nvt "$HOME" "${STOW_IGNORE_ARGUMENTS[@]}" "${DIRECTORIES[@]}"; then
        if is_dry_run; then
            warn "Stow preview found conflicts. Resolve them before a real configure run."
        else
            die "Stow preview found conflicts; no packages were linked. Back up the reported targets and retry."
        fi
    fi
elif is_dry_run; then
    run stow -nvt "$HOME" "${STOW_IGNORE_ARGUMENTS[@]}" "${DIRECTORIES[@]}"
else
    die "GNU Stow is unavailable. Run 'bash install.sh' first."
fi

if ! is_dry_run; then
    run stow -vt "$HOME" "${STOW_IGNORE_ARGUMENTS[@]}" "${DIRECTORIES[@]}"
fi

# Manually copy the global .gitignore as we should avoid linking VCS ignore files.
GITIGNORE_TARGET="$HOME/.gitignore"
if [[ -e "$GITIGNORE_TARGET" ]] && ! cmp -s ./git/.gitignore "$GITIGNORE_TARGET"; then
    warn "Leaving existing $GITIGNORE_TARGET in place; not overwriting it."
elif [[ -e "$GITIGNORE_TARGET" ]]; then
    printf "$GREEN$BOLD%s$NORMAL\n" "✔ $GITIGNORE_TARGET is already up to date"
else
    run cp ./git/.gitignore "$GITIGNORE_TARGET"
fi
