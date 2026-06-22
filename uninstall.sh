#!/usr/bin/env bash
set -Eeuo pipefail

DOTFILES_LOCATION="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_LOCATION
cd "$DOTFILES_LOCATION" || exit 1

source _scripts/colors.sh
source "$DOTFILES_LOCATION/_scripts/lib.sh"

UNINSTALL_SCOPE="brewfile"
UNINSTALL_SCOPE_EXPLICIT=""
UNINSTALL_PURGE_RUNTIMES=0
UNINSTALL_ZAP_APP_DATA=0

print_uninstall_usage() {
    cat <<'USAGE'
Usage: bash uninstall.sh [options]

Default scope:
  Unlink dotfiles and uninstall only installed formulae, casks, and taps
  declared in _homebrew/Brewfile. Homebrew cask zap is disabled.

Scope options (choose at most one):
  --brewfile          Explicitly select the default managed-package scope.
  --links-only        Unlink dotfiles; keep Homebrew.
  --all-homebrew      Unlink dotfiles, uninstall every Homebrew cask, then run
                      Homebrew's official whole-prefix uninstaller. That script
                      also targets Homebrew caches, logs, and integration files.

Additional destructive options:
  --zap-app-data      With the default or --all-homebrew scope, run cask zap
                      procedures after a separate exact confirmation. May
                      remove profiles, user data, and shared resources.
  --purge-runtimes    Remove ~/.nvm, ~/.npm, ~/.bower, ~/.pyenv, and ~/.pylint.d
                      after a separate exact confirmation.

Common options:
  --dry-run, -n       Print planned commands and inventories without changing
                      anything. It does not enumerate every file targeted by
                      Homebrew's official uninstaller.
  --help, -h          Show this help.
USAGE
}

select_uninstall_scope() {
    local requested_scope="$1"

    if [[ -n "$UNINSTALL_SCOPE_EXPLICIT" ]]; then
        die "Specify exactly one uninstall scope at most once."
    fi

    UNINSTALL_SCOPE="$requested_scope"
    UNINSTALL_SCOPE_EXPLICIT=1
}

parse_uninstall_args() {
    local argument

    for argument in "$@"; do
        case "$argument" in
            --dry-run|-n)
                DOTFILES_DRY_RUN=1
                ;;
            --brewfile)
                select_uninstall_scope "brewfile"
                ;;
            --links-only)
                select_uninstall_scope "links-only"
                ;;
            --all-homebrew)
                select_uninstall_scope "all-homebrew"
                ;;
            --zap-app-data)
                UNINSTALL_ZAP_APP_DATA=1
                ;;
            --purge-runtimes)
                UNINSTALL_PURGE_RUNTIMES=1
                ;;
            --help|-h)
                print_uninstall_usage
                exit 0
                ;;
            *)
                print_uninstall_usage >&2
                die "Unknown argument: $argument"
                ;;
        esac
    done

    if [[ "$UNINSTALL_SCOPE" == "links-only" && "$UNINSTALL_ZAP_APP_DATA" == "1" ]]; then
        die "--zap-app-data cannot be combined with --links-only."
    fi

    export DOTFILES_DRY_RUN
    export UNINSTALL_SCOPE
    export UNINSTALL_PURGE_RUNTIMES
    export UNINSTALL_ZAP_APP_DATA
}

confirm_exact() {
    local phrase="$1"
    local description="$2"
    local answer

    if is_dry_run; then
        log "DRY RUN: exact confirmation '$phrase' would be required for $description."
        return 0
    fi

    printf "$RED_BACKGROUND%s$NORMAL\n" "$description"
    printf "Type '%s' to continue: " "$phrase"
    if ! IFS= read -r answer; then
        return 1
    fi

    [[ "$answer" == "$phrase" ]]
}

confirm_plan() {
    local primary_phrase
    local primary_description

    case "$UNINSTALL_SCOPE" in
        links-only)
            primary_phrase="unlink dotfiles"
            primary_description="This will remove only GNU Stow-managed dotfile links"
            ;;
        brewfile)
            primary_phrase="uninstall managed"
            primary_description="This will unlink dotfiles and uninstall only entries declared in _homebrew/Brewfile"
            ;;
        all-homebrew)
            primary_phrase="remove all homebrew"
            primary_description="This will unlink dotfiles, uninstall every Homebrew cask, and run Homebrew's official uninstaller, including its cache, log, and integration-file cleanup"
            ;;
        *)
            die "Unknown uninstall scope: $UNINSTALL_SCOPE"
            ;;
    esac

    confirm_exact "$primary_phrase" "$primary_description" || return 1

    if [[ "$UNINSTALL_PURGE_RUNTIMES" == "1" ]]; then
        confirm_exact \
            "purge runtimes" \
            "This also deletes all NVM/npm/Bower and pyenv/Pylint data listed in --help" || return 1
    fi

    if [[ "$UNINSTALL_ZAP_APP_DATA" == "1" ]]; then
        confirm_exact \
            "zap app data" \
            "Homebrew cask zap may remove profiles, caches, user data, and resources shared with other applications" || return 1
    fi
}

parse_uninstall_args "$@"
enable_error_trap

# Homebrew inventory is read and validated before confirmation or mutation.
# Links-only must remain usable when Homebrew is absent.
if [[ "$UNINSTALL_SCOPE" != "links-only" ]]; then
    source _scripts/uninstall-homebrew.sh
    prepare_homebrew_plan
    print_homebrew_plan
fi

if ! confirm_plan; then
    printf "$CYAN%s$NORMAL\n" "No changes made. Confirmation did not match."
    exit 1
fi

# Download and syntax-check the official whole-prefix uninstaller before the
# first mutation. Brewfile-only and links-only scopes never download it.
if [[ "$UNINSTALL_SCOPE" == "all-homebrew" ]]; then
    prepare_homebrew_uninstaller
fi

# Always unlink first while GNU Stow is still available.
source _scripts/unstow.sh

if [[ "$UNINSTALL_PURGE_RUNTIMES" == "1" ]]; then
    source _scripts/uninstall-pyenv.sh
    source _scripts/uninstall-nvm.sh
else
    log "Preserving pyenv, NVM, npm, Bower, and their installed runtimes."
fi

if [[ "$UNINSTALL_SCOPE" == "links-only" ]]; then
    log "Links-only uninstall complete; Homebrew was not changed."
else
    execute_homebrew_plan
fi
