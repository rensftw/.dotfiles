#!/usr/bin/env bash
################################################################################
# Daily maintenance
################################################################################

# Plugins with breaking changes are skipped and listed for manual review.
#   tend            update everything
#   tend --dry-run  print planned commands without running them
#   tend homebrew   update Homebrew only   (alias: brew)
#   tend neovim     update Neovim only     (alias: nvim)
#   tend tmux       update tmux plugins (tpm) only
#   tend pi         update Pi agent + extensions only
#
# Internal helpers are prefixed `_tend_` because this file is sourced into the
# interactive shell.

_tend_usage() {
    printf "%s%s%s\n" "${YELLOW:-}" "usage: tend [--dry-run] [all|homebrew|neovim|tmux|pi]" "${NC:-}"
}

_tend_path_without_pyenv_shims() {
    local path_value="$1"
    local pyenv_shims="${PYENV_ROOT:-}/shims"

    if [[ -z "${PYENV_ROOT:-}" ]]; then
        printf "%s" "$path_value"
        return 0
    fi

    # Use a colon sandwich so the same replacement handles start/middle/end.
    path_value=":${path_value}:"
    path_value="${path_value//:${pyenv_shims}:/:}"
    path_value="${path_value#:}"
    path_value="${path_value%:}"
    printf "%s" "$path_value"
}

_tend_save_trap() {
    local signal="$1" var_name="$2" saved_trap=""

    if [[ -n "${ZSH_VERSION:-}" ]]; then
        # In zsh, `$(trap)` runs in a subshell where traps are reset. Capture the
        # current-shell output through a temporary file instead.
        local trap_file=""
        trap_file="$(mktemp "${TMPDIR:-/tmp}/tend-trap.XXXXXX")" || return 1
        trap > "$trap_file"
        saved_trap="$(grep -E " ${signal}$" "$trap_file" || true)"
        rm -f "$trap_file"
    else
        saved_trap="$(trap -p "$signal")"
    fi

    printf -v "$var_name" "%s" "$saved_trap"
}

_tend_restore_trap() {
    local signal="$1" saved_trap="$2"

    if [[ -n "$saved_trap" ]]; then
        eval "$saved_trap"
    else
        trap - "$signal"
    fi
}

_tend_reset_run_state() {
    _tend_dry_run=false
    _tend_interrupted=false
    _tend_failures=""
    _tend_final_status=0
    _tend_clean_path="$(_tend_path_without_pyenv_shims "$PATH")"
    _tend_lol="cat"

    command -v lolcat &>/dev/null && _tend_lol="lolcat"
    return 0
}

_tend_cleanup_run_state() {
    unset _tend_dry_run _tend_interrupted _tend_failures _tend_final_status _tend_clean_path _tend_lol
}

_tend_fail() {
    local name="$1" rc="${2:-1}"

    [[ "$rc" -eq 0 ]] && rc=1
    _tend_failures="${_tend_failures}${_tend_failures:+, }${name}"
    [[ "$_tend_final_status" -eq 0 ]] && _tend_final_status="$rc"
    return 0
}

_tend_header() {
    echo ""
    if command -v figlet &>/dev/null; then
        figlet -f digital "$1" | "$_tend_lol"
    else
        printf "== %s ==\n" "$1" | "$_tend_lol"
    fi
}

_tend_print_cmd() {
    printf "%s❯ %s%s\n" "${CYAN:-}" "$1" "${NC:-}"
}

_tend_run() {
    local label="$1"
    shift

    _tend_print_cmd "$label"
    [[ "$_tend_dry_run" == true ]] && return 0

    local rc=0
    if "$@"; then
        rc=0
    else
        rc=$?
    fi

    [[ "$_tend_interrupted" == true ]] && return 130
    return "$rc"
}

_tend_show_banner() {
    if command -v figlet &>/dev/null; then
        figlet -f ogre "Greetings, earthling!" | "$_tend_lol"
    else
        echo "☀ Greetings, earthling!" | "$_tend_lol"
    fi

    [[ "$_tend_dry_run" == true ]] && printf "  %sdry run — no changes will be made%s\n" "${YELLOW:-}" "${NC:-}"
    return 0
}

_tend_brew_outdated() {
    local outdated=""

    _tend_print_cmd "brew outdated --greedy --verbose"
    [[ "$_tend_dry_run" == true ]] && return 0

    outdated="$(env PATH="$_tend_clean_path" brew outdated --greedy --verbose)" || return $?

    if [[ -n "$outdated" ]]; then
        printf "%s\n" "$outdated" | sed "s/^/  ${GREEN:-}•${NC:-} /"
    else
        printf "  %s✔ all up to date%s\n" "${GREEN:-}" "${NC:-}"
    fi
}

_tend_update_homebrew() {
    _tend_header "Homebrew"

    # Run with pyenv shims stripped from PATH (matches the brew alias).
    _tend_run "brew update" env PATH="$_tend_clean_path" brew update || return $?
    _tend_brew_outdated || return $?
    _tend_run "brew upgrade --greedy --no-ask" env PATH="$_tend_clean_path" brew upgrade --greedy --no-ask || return $?
    _tend_run "brew cleanup --prune=all" env PATH="$_tend_clean_path" brew cleanup --prune=all || return $?
    _tend_run "brew autoremove" env PATH="$_tend_clean_path" brew autoremove
}

_tend_update_neovim() {
    local updater="${DOTFILES_LOCATION:-$HOME/.dotfiles}/_scripts/nvim-update.lua"

    # The updater prints its own detailed headers during real runs; dry-run gets
    # a summary header here.
    [[ "$_tend_dry_run" == true ]] && _tend_header "Neovim"

    if [[ ! -r "$updater" && "$_tend_dry_run" != true ]]; then
        echo ""
        printf "  %s✗ updater not found: %s%s\n" "${RED:-}" "$updater" "${NC:-}"
        return 1
    fi

    _tend_run "nvim --headless -c \"luafile $updater\" -c \"qa!\"" nvim --headless -c "luafile $updater" -c "qa!"
}

_tend_update_tmux() {
    local tpm_update="$HOME/.tmux/plugins/tpm/bin/update_plugins"

    _tend_header "Tmux"

    if [[ ! -x "$tpm_update" && "$_tend_dry_run" != true ]]; then
        printf "  %s✗ tpm not found: %s%s\n" "${RED:-}" "$tpm_update" "${NC:-}"
        return 1
    fi

    _tend_run "tpm update_plugins all" "$tpm_update" all
}

_tend_update_pi() {
    local pi_status=0

    # Pi coding agent + its package-managed extensions (e.g. pi-web-access).
    # `--no-approve` ignores project-local Pi files in the current directory,
    # avoiding accidental updates from untrusted repositories.
    # Custom .ts extensions (goal.ts, answer.ts, …) are stow-managed in this
    # repo and update via git, not `pi update`.
    _tend_header "Pi"

    if ! command -v pi &>/dev/null && [[ "$_tend_dry_run" != true ]]; then
        printf "  %s✗ pi not found on PATH%s\n" "${RED:-}" "${NC:-}"
        return 1
    fi

    _tend_run "pi update --self --no-approve" command pi update --self --no-approve || pi_status=$?
    if [[ "$pi_status" -ne 0 ]]; then
        [[ "$_tend_interrupted" == true ]] || printf "  %s✗ pi self-update failed; skipping extension update%s\n" "${RED:-}" "${NC:-}"
        return "$pi_status"
    fi

    if [[ "$_tend_dry_run" != true ]]; then
        hash -r 2>/dev/null || true
        rehash 2>/dev/null || true
    fi

    _tend_run "pi update --extensions --no-approve" command pi update --extensions --no-approve
}

_tend_run_task() {
    local name="$1" fn="$2" task_rc=0

    [[ "$_tend_interrupted" == true ]] && return 0

    if "$fn"; then
        task_rc=0
    else
        task_rc=$?
    fi

    if [[ "$task_rc" -eq 130 ]]; then
        _tend_interrupted=true
    elif [[ "$task_rc" -ne 0 ]]; then
        _tend_fail "$name" "$task_rc"
    fi

    return 0
}

_tend_print_summary() {
    echo ""

    if [[ "$_tend_final_status" -ne 0 ]]; then
        printf "  %s✗ completed with failures: %s%s\n" "${RED:-}" "$_tend_failures" "${NC:-}"
        return "$_tend_final_status"
    fi

    if [[ "$_tend_dry_run" == true ]]; then
        echo "  ✓ dry run complete — no changes made" | "$_tend_lol"
        return 0
    fi

    _tend_print_random_art
    echo "  ✓ all done — have a great day!" | "$_tend_lol"
}

_tend_print_random_art() {
    local art_dir="${DOTFILES_LOCATION:-$HOME/.dotfiles}/_scripts/ascii"
    local art_count=6 art_index art_name=""

    art_index=$((RANDOM % art_count + 1))
    art_name="$(printf "%s\n" clover.txt mushroom-house.txt mushroom-house-2.txt plant.txt flower.txt cat.txt | sed -n "${art_index}p")"

    [[ -n "$art_name" && -r "$art_dir/$art_name" ]] && "$_tend_lol" < "$art_dir/$art_name"
    return 0
}

tend() {
    local target="all" target_set=false dry_run=false arg
    local old_int_trap="" old_term_trap=""

    for arg in "$@"; do
        case "$arg" in
            --dry-run)
                dry_run=true
                ;;
            -h|--help)
                _tend_usage
                return 0
                ;;
            all|homebrew|brew|neovim|nvim|tmux|pi)
                if [[ "$target_set" == true ]]; then
                    _tend_usage >&2
                    return 1
                fi
                target="$arg"
                target_set=true
                ;;
            *)
                _tend_usage >&2
                return 1
                ;;
        esac
    done

    _tend_save_trap INT old_int_trap || return $?
    _tend_save_trap TERM old_term_trap || return $?

    _tend_reset_run_state
    _tend_dry_run="$dry_run"

    trap '_tend_interrupted=true' INT TERM

    _tend_show_banner

    case "$target" in
        all)
            _tend_run_task "homebrew" _tend_update_homebrew
            _tend_run_task "neovim" _tend_update_neovim
            _tend_run_task "tmux" _tend_update_tmux
            _tend_run_task "pi" _tend_update_pi
            ;;
        homebrew|brew)
            _tend_run_task "homebrew" _tend_update_homebrew
            ;;
        neovim|nvim)
            _tend_run_task "neovim" _tend_update_neovim
            ;;
        tmux)
            _tend_run_task "tmux" _tend_update_tmux
            ;;
        pi)
            _tend_run_task "pi" _tend_update_pi
            ;;
    esac

    [[ "$_tend_interrupted" == true ]] && _tend_fail "interrupted" 130

    _tend_restore_trap INT "$old_int_trap"
    _tend_restore_trap TERM "$old_term_trap"

    local tend_rc=0
    if _tend_print_summary; then
        tend_rc=0
    else
        tend_rc=$?
    fi
    _tend_cleanup_run_state
    return "$tend_rc"
}
