#!/usr/bin/env bash

# Shared safety, logging, and dry-run helpers. Keep this file compatible with
# the Bash 3.2 version shipped by macOS.
if [[ "${DOTFILES_LIB_LOADED:-0}" == "1" ]]; then
    return 0 2>/dev/null || exit 0
fi
DOTFILES_LIB_LOADED=1

DOTFILES_DRY_RUN="${DOTFILES_DRY_RUN:-0}"
export DOTFILES_DRY_RUN

log() {
    printf '%s\n' "$*"
}

warn() {
    printf 'WARNING: %s\n' "$*" >&2
}

die() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

is_dry_run() {
    [[ "$DOTFILES_DRY_RUN" == "1" ]]
}

print_usage() {
    printf 'Usage: bash %s [--dry-run|-n]\n' "${0##*/}"
}

parse_common_args() {
    local argument

    for argument in "$@"; do
        case "$argument" in
            --dry-run|-n)
                DOTFILES_DRY_RUN=1
                ;;
            --help|-h)
                print_usage
                exit 0
                ;;
            *)
                print_usage >&2
                die "Unknown argument: $argument"
                ;;
        esac
    done

    export DOTFILES_DRY_RUN
}

print_command() {
    local argument

    printf '$'
    for argument in "$@"; do
        printf ' %q' "$argument"
    done
    printf '\n'
}

run() {
    if is_dry_run; then
        print_command "$@"
        return 0
    fi

    "$@"
}

run_shell() {
    local command_text="$1"

    if is_dry_run; then
        print_command /bin/bash -o pipefail -c "$command_text"
        return 0
    fi

    /bin/bash -o pipefail -c "$command_text"
}

_dotfiles_error_handler() {
    local status="$1"
    local source_file="$2"
    local line_number="$3"
    local failed_command="$4"

    trap - ERR
    printf 'ERROR: command failed with status %s at %s:%s\n' \
        "$status" "$source_file" "$line_number" >&2
    printf '       %s\n' "$failed_command" >&2
    exit "$status"
}

enable_error_trap() {
    set -E
    trap '_dotfiles_error_handler "$?" "${BASH_SOURCE[0]:-$0}" "$LINENO" "$BASH_COMMAND"' ERR
}

# macos.sh uses these commands directly many times. In dry-run mode, replace
# them with functions that only print their fully escaped invocation.
enable_dry_run_command_shims() {
    if ! is_dry_run; then
        return 0
    fi

    defaults() {
        run /usr/bin/defaults "$@"
    }

    sudo() {
        run /usr/bin/sudo "$@"
    }

}

guard_brew_prefix() {
    local prefix="$1"

    case "$prefix" in
        /opt/homebrew|/usr/local)
            ;;
        *)
            die "Refusing to remove an unexpected Homebrew prefix: $prefix"
            ;;
    esac
}

rm_rf() {
    local path

    for path in "$@"; do
        case "$path" in
            ''|/|"$HOME"|"${BREW_PREFIX:-__unset__}")
                die "Refusing unsafe recursive removal target: ${path:-<empty>}"
                ;;
        esac
        run rm -rf -- "$path"
    done
}
