#!/usr/bin/env bash
################################################################################
# Daily maintenance
################################################################################

# Plugins with breaking changes are skipped and listed for manual review.
#   tend            update everything
#   tend --dry-run  print planned commands without running them
#   tend --force    force-rebuild Neovim treesitter parsers (skips the plugin-bump gate)
#   tend homebrew   update Homebrew only   (alias: brew)
#   tend alacritty  update Alacritty only (from GitHub releases)
#   tend neovim     update Neovim only     (alias: nvim)
#   tend tmux       update tmux plugins (tpm) only
#   tend pi         update managed Pi + extensions only
#   tend claude     update Claude Code only
#
# Internal helpers are prefixed `_tend_` because this file is sourced into the
# interactive shell. The run itself executes in a subshell (_tend_main) so its
# traps and _tend_* state are scoped to the invocation and can never leak into
# — or clobber — the interactive shell's own handlers.

_tend_usage() {
    printf "%s%s%s\n" "${YELLOW:-}" "usage: tend [--dry-run] [--force] [all|homebrew|alacritty|neovim|tmux|pi|claude]" "${NC:-}"
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
    if command -v toilet &>/dev/null; then
        toilet -f smbraille "$1" | "$_tend_lol"
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
    # The greeting is reserved for a bare `tend`; any argument skips it.
    if [[ "$_tend_greet" == true ]]; then
        if command -v toilet &>/dev/null; then
            toilet -f smblock "Greetings, earthling!" | "$_tend_lol"
        else
            echo "☀ Greetings, earthling!" | "$_tend_lol"
        fi
    fi

    [[ "$_tend_dry_run" == true ]] && printf "  %sdry run — no changes will be made%s\n" "${YELLOW:-}" "${NC:-}"
    return 0
}

_tend_brew_outdated() {
    local outdated="" skipped=""

    _tend_print_cmd "brew outdated --verbose"
    [[ "$_tend_dry_run" == true ]] && return 0

    # First list = what the upgrade step will act on (same env var as there).
    # The second drops the env var (exported by .zshrc too), so brew also
    # lists self-updating casks whose app bundle is actually older than the
    # tap. `--greedy` would compare the Caskroom record instead, which goes
    # stale once an app updates itself. The extras are shown, not upgraded.
    outdated="$(env PATH="$_tend_clean_path" HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS=1 brew outdated --verbose)" || return $?
    skipped="$(env -u HOMEBREW_NO_UPGRADE_AUTO_UPDATES_CASKS PATH="$_tend_clean_path" brew outdated --verbose)" || return $?
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

_tend_update_alacritty() {
    local installer="${DOTFILES_LOCATION:-$HOME/.dotfiles}/_scripts/install-alacritty.sh"

    # Homebrew disabled the alacritty cask (the app isn't notarized) and skips
    # disabled casks on upgrade, so updates come straight from GitHub releases.
    # The installer also adopts a leftover cask install on its first run.
    _tend_header "Alacritty"

    if [[ ! -r "$installer" && "$_tend_dry_run" != true ]]; then
        printf "  %s✗ installer not found: %s%s\n" "${RED:-}" "$installer" "${NC:-}"
        return 1
    fi

    _tend_run "bash $installer" env PATH="$_tend_clean_path" bash "$installer"
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
    # Hide git's "| Already up to date." lines: they repeat what the
    # '"<name>" update success' lines say and, because tpm runs the updates in
    # parallel, land detached from their plugin. The failure scan below still
    # reads the unfiltered output.
    [[ -n "$output" ]] && printf "%s\n" "$output" | sed -E '/^[[:space:]]*\| Already up to date\.$/d'

    [[ "$_tend_interrupted" == true ]] && return 130
    [[ "$rc" -ne 0 ]] && return "$rc"
    if printf "%s\n" "$output" | grep -q '" update fail$'; then
        printf "  %s✗ one or more tmux plugins failed to update%s\n" "${RED:-}" "${NC:-}"
        return 1
    fi
    return 0
}

_tend_update_pi() {
    local managed_root="${PI_MANAGED_INSTALL_ROOT:-${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}/install}"
    managed_root="${managed_root%/}"
    local managed_marker="$managed_root/managed-install.json"

    # The managed installer pins Pi's complete dependency tree. `--all` updates
    # that managed release and package-managed extensions (e.g. pi-web-access)
    # in one command. `--no-approve` ignores project-local Pi files in the
    # current directory, avoiding accidental updates from untrusted repos.
    # Custom .ts extensions (goal.ts, answer.ts, …) remain stow-managed here.
    _tend_header "Pi"

    if [[ "$_tend_dry_run" != true ]]; then
        if ! command -v pi &>/dev/null; then
            printf "  %s✗ pi not found on PATH; run bash configure.sh to install it%s\n" "${RED:-}" "${NC:-}"
            return 1
        fi
        if [[ ! -f "$managed_marker" ]]; then
            printf "  %s✗ expected a managed Pi installation at %s%s\n" "${RED:-}" "$managed_root" "${NC:-}"
            printf "  reinstall with: curl -fsSL https://pi.dev/install.sh | sh\n"
            return 1
        fi
    fi

    _tend_run "pi update --all --no-approve" command pi update --all --no-approve
}

_tend_update_claude() {
    # The native install updates itself in the background; `claude update`
    # just applies a pending release now. `command` skips the
    # `caffeinate claude` alias.
    _tend_header "Claude Code"

    if [[ "$_tend_dry_run" != true ]] && ! command -v claude &>/dev/null; then
        printf "  %s✗ claude not found on PATH%s\n" "${RED:-}" "${NC:-}"
        printf "  install with: curl -fsSL https://claude.ai/install.sh | bash\n"
        return 1
    fi

    _tend_run "claude update" command claude update
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

    # Like the greeting, the art is reserved for a bare `tend`.
    [[ "$_tend_greet" == true ]] && _tend_print_random_art
    echo "  ✓ all done — have a great day!" | "$_tend_lol"
}

_tend_print_random_art() {
    local art_dir="${DOTFILES_LOCATION:-$HOME/.dotfiles}/_scripts/braille-dot-art"
    local art_file=""

    # Every *.txt in the directory is in the rotation; adding or removing art
    # needs no edit here. zsh would abort on an unmatched glob, so null_glob
    # (function-scoped via local_options) lets it expand to nothing; bash
    # leaves it as the literal pattern. The guard below covers both.
    [[ -n "${ZSH_VERSION:-}" ]] && setopt local_options null_glob
    set -- "$art_dir"/*.txt
    [[ $# -eq 0 || ! -e "$1" ]] && return 0

    # The subshell inherits $RANDOM's seed and the parent never advances it,
    # so without re-seeding every run in a session would pick the same art.
    RANDOM=$(date +%s)
    shift $((RANDOM % $#))
    art_file="$1"

    [[ -r "$art_file" ]] && "$_tend_lol" < "$art_file"
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
            all|homebrew|brew|alacritty|neovim|nvim|tmux|pi|claude)
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

    _tend_greet=false
    [[ $# -eq 0 ]] && _tend_greet=true
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
            _tend_run_task "alacritty" _tend_update_alacritty
            _tend_run_task "neovim" _tend_update_neovim
            _tend_run_task "tmux" _tend_update_tmux
            _tend_run_task "pi" _tend_update_pi
            _tend_run_task "claude" _tend_update_claude
            ;;
        homebrew|brew)
            _tend_run_task "homebrew" _tend_update_homebrew
            ;;
        alacritty)
            _tend_run_task "alacritty" _tend_update_alacritty
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
        claude)
            _tend_run_task "claude" _tend_update_claude
            ;;
    esac

    [[ "$_tend_interrupted" == true ]] && _tend_fail "interrupted" 130

    _tend_print_summary
)
