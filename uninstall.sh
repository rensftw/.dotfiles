#!/usr/bin/env bash
set -euo pipefail

DOTFILES_LOCATION="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_LOCATION
cd "$DOTFILES_LOCATION" || exit 1

# Import ANSI escape codes for colors
source _scripts/colors.sh
source "$DOTFILES_LOCATION/_scripts/lib.sh"
parse_common_args "$@"

if is_dry_run; then
    log "DRY RUN: skipping uninstall confirmation prompt."
    ANSWER="yes"
else
    printf "$RED_BACKGROUND%s$NORMAL " "This action is irreversible. Type 'yes' to proceed: "
    read -r ANSWER
fi

if [[ "$ANSWER" == "yes" ]]; then
    # Remove pyenv artifacts
    source _scripts/uninstall-pyenv.sh

    # Uninstall nvm and all artifacts
    source _scripts/uninstall-nvm.sh

    # Remove all dotfiles
    source _scripts/unstow.sh

    # Remove all casks/taps/formulae and then uninstall Homebrew itself
    source _scripts/uninstall-homebrew.sh
else
    printf "$CYAN%s$NORMAL\n" "No changes made. Quitting.."
fi
