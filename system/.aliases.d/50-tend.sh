#!/usr/bin/env bash
################################################################################
# Daily maintenance
################################################################################

# Plugins with breaking changes are skipped and listed for manual review.
#   tend            update everything
#   tend --dry-run  print planned commands without running them
#   tend --force    force-rebuild Neovim treesitter parsers (skips the plugin-bump gate)
#   tend homebrew   update Homebrew only   (alias: brew)
#   tend neovim     update Neovim only     (alias: nvim)
#   tend tmux       update tmux plugins (tpm) only
#   tend pi         update Pi agent + extensions only
#
# Internal helpers are prefixed `_tend_` because this file is sourced into the
# interactive shell. The run itself executes in a subshell (_tend_main) so its
# traps and _tend_* state are scoped to the invocation and can never leak into
# — or clobber — the interactive shell's own handlers.

_tend_usage() {
    printf "%s%s%s\n" "${YELLOW:-}" "usage: tend [--dry-run] [--force] [all|homebrew|neovim|tmux|pi]" "${NC:-}"
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
    local outdated="" skipped=""

    _tend_print_cmd "brew outdated --greedy --verbose"
    [[ "$_tend_dry_run" == true ]] && return 0

    # First list = what the upgrade step will act on (same env var as there);
    # the --greedy extras are self-updating casks, shown for visibility only.
    outdated="$(env PATH="$_tend_clean_path" HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS=1 brew outdated --verbose)" || return $?
    skipped="$(env PATH="$_tend_clean_path" brew outdated --greedy --verbose)" || return $?
    if [[ -n "$outdated" && -n "$skipped" ]]; then
        skipped="$(printf "%s\n" "$skipped" | grep -Fxv -f <(printf "%s\n" "$outdated"))"
    fi

    if [[ -z "$outdated" && -z "$skipped" ]]; then
        printf "  %s✔ all up to date%s\n" "${GREEN:-}" "${NC:-}"
        return 0
    fi
    [[ -n "$outdated" ]] && printf "%s\n" "$outdated" | sed "s/^/  ${GREEN:-}•${NC:-} /"
    [[ -n "$skipped" ]] && printf "%s\n" "$skipped" | sed "s/^/  ${YELLOW:-}•${NC:-} /; s/$/ — self-updating, left to the app/"
    return 0
}

_tend_update_homebrew() {
    local rc=0

    _tend_header "Homebrew"

    # Run with pyenv shims stripped from PATH (matches the brew alias).
    # A failed step doesn't abort the rest: `brew cleanup` especially must
    # still run after a failed upgrade, because a full disk is a likely cause
    # of the failure and cleanup is the step that frees space. Interrupts do
    # stop the sequence.
    _tend_run "brew update" env PATH="$_tend_clean_path" brew update || rc=$?
    [[ "$_tend_interrupted" == true ]] && return 130

    _tend_brew_outdated || rc=$?
    [[ "$_tend_interrupted" == true ]] && return 130

    # Leave auto_updates casks (Postman, Chrome, …) to their own updaters:
    # brew force-replacing a self-updating app is how upgrades wedge (Postman
    # here is even root-owned, so brew needs a sudo prompt mid-upgrade).
    # Newer brew upgrades them by default; the env var restores the skip.
    # Hand one back to brew with HOMEBREW_UPGRADE_GREEDY_CASKS="name".
    _tend_run "brew upgrade --no-ask" env PATH="$_tend_clean_path" HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS=1 brew upgrade --no-ask || rc=$?
    [[ "$_tend_interrupted" == true ]] && return 130

    _tend_run "brew cleanup --prune=all" env PATH="$_tend_clean_path" brew cleanup --prune=all || rc=$?
    [[ "$_tend_interrupted" == true ]] && return 130

    _tend_run "brew autoremove" env PATH="$_tend_clean_path" brew autoremove || rc=$?

    return "$rc"
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

    # `--force` sets TEND_FORCE_TS=1 so the updater rebuilds treesitter parsers
    # even when tree-sitter-manager.nvim itself wasn't bumped.
    local force_ts="" label="nvim --headless -c \"luafile $updater\" -c \"qa!\""
    if [[ "$_tend_force" == true ]]; then
        force_ts="1"
        label="TEND_FORCE_TS=1 $label"
    fi

    _tend_run "$label" env TEND_FORCE_TS="$force_ts" nvim --headless -c "luafile $updater" -c "qa!"
}

_tend_update_tmux() {
    local tpm_update="$HOME/.tmux/tpm/bin/update_plugins"
    local output="" rc=0

    _tend_header "Tmux"

    if [[ ! -x "$tpm_update" && "$_tend_dry_run" != true ]]; then
        printf "  %s✗ tpm not found: %s%s\n" "${RED:-}" "$tpm_update" "${NC:-}"
        return 1
    fi

    _tend_print_cmd "tpm update_plugins all"
    [[ "$_tend_dry_run" == true ]] && return 0

    # tpm backgrounds each plugin's update, so its FAIL flag is set in a
    # subshell and update_plugins exits 0 even when a `git pull` fails. The
    # only reliable failure signal is the per-plugin '"<name>" update fail'
    # line (on stderr) — capture everything and scan for it.
    output="$("$tpm_update" all 2>&1)" || rc=$?
    [[ -n "$output" ]] && printf "%s\n" "$output"

    [[ "$_tend_interrupted" == true ]] && return 130
    [[ "$rc" -ne 0 ]] && return "$rc"
    if printf "%s\n" "$output" | grep -q '" update fail$'; then
        printf "  %s✗ one or more tmux plugins failed to update%s\n" "${RED:-}" "${NC:-}"
        return 1
    fi
    return 0
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
    local art_name=""

    # Rotation art only — tools-ready-ascii.txt in the same directory is
    # configure.sh's banner, so the directory can't simply be globbed.
    set -- clover.txt mushroom-house.txt mushroom-house-2.txt plant.txt flower.txt cat.txt gingko.txt

    # The subshell inherits $RANDOM's seed and the parent never advances it,
    # so without re-seeding every run in a session would pick the same art.
    RANDOM=$(date +%s)
    shift $((RANDOM % $#))
    art_name="$1"

    [[ -n "$art_name" && -r "$art_dir/$art_name" ]] && "$_tend_lol" < "$art_dir/$art_name"
    return 0
}

# Runs in the interactive shell; anything that must affect it belongs here.
tend() {
    local rc=0
    _tend_main "$@" || rc=$?

    # Binaries may have been replaced during the run (pi self-update, brew
    # upgrades); refresh the parent shell's command hash so they're found at
    # their new paths. (bash: hash -r, zsh: rehash.)
    hash -r 2>/dev/null || true
    rehash 2>/dev/null || true
    return "$rc"
}

# The subshell body (note the parentheses): traps and all _tend_* run state
# are scoped to this invocation and vanish on exit — nothing to save,
# restore, or clean up in the interactive shell.
_tend_main() (
    local target="all" target_set=false dry_run=false force=false arg

    for arg in "$@"; do
        case "$arg" in
            --dry-run)
                dry_run=true
                ;;
            --force)
                force=true
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

    _tend_dry_run="$dry_run"
    _tend_force="$force"
    _tend_interrupted=false
    _tend_failures=""
    _tend_final_status=0
    _tend_clean_path="$(_tend_path_without_pyenv_shims "$PATH")"
    _tend_lol="cat"
    command -v lolcat &>/dev/null && _tend_lol="lolcat"

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

    _tend_print_summary
)
