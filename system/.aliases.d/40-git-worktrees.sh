################################################################################
# Git worktree management
# Depends on: 20-git-helpers.sh (_mb)
################################################################################

# Clone repository as bare repo for worktree workflow
clone-bare() {
    if [ $# -ne 2 ]; then
        printf "$CYAN%s$NC\n" "Usage: clone-bare <repository-url> <local-repo-path>"
        return 1
    fi

    local repo_url="$1"
    local local_repo_path="$2"

    # Check if target directory exists and has .git
    if [ -e "$local_repo_path/.git" ]; then
        printf "$RED$BOLD%s$NC\n\n" "Aborting: nested repos are not advisable."
        return 1
    fi

    # Create directory if it doesn't exist and it's not the current working directory
    if [ "$local_repo_path" != "." ] && [ ! -d "$local_repo_path" ]; then
        mkdir -p "$local_repo_path"
    fi

    cd "$local_repo_path" || return 1

    printf "$MAGENTA$BOLD%s$NC\n" "Cloning $repo_url as bare repository in $(pwd)"

    # Clone as bare repository
    git clone --bare --filter=blob:none --single-branch "$repo_url" .bare

    # Create .git file pointing to bare repo
    echo "gitdir: ./.bare" > .git

    # Configure remote to fetch all branches (dangerous for massive repos)
    # This is needed for fetching individual branches in the future
    # Do NOT: `git fetch` everything blindly
    # Do: `git fetch origin HEAD`
    git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"

    # # Fetch all branches
    # git fetch --filter=blob:none origin

    # TIP 1: Discover remote branches
    # Do: git ls-remote --heads
    # Don't: git branch -r

    # TIP 2: Fetch changes
    # Do: git fetch origin HEAD
    # Don't: git fetch

    # Remove reference for default branch (we cannot make a worktree for an existing branch ref)
    git branch -D "$(git rev-parse --abbrev-ref HEAD)"

    printf "$GREEN%s$NC%s$BOLD%s$NC\n" " "  " Bare repository has been partially cloned in: " "$local_repo_path"
    printf "$GREEN$BOLD%s$NC\n\n" '  Ready to use worktrees!'
    printf "$YELLOW_BACKGROUND%s$NC\n $YELLOW%s$NC\n\n" " Discover remote branches:" "git ls-remote --heads"
    printf "$CYAN_BACKGROUND%s$NC\n" "  Available commands:"
    printf "$CYAN%s$NC\n" "  gwa <branch-name> - to create a worktree"
    printf "$CYAN%s$NC\n" "  gwl, gws, gwr, gwp "
}

# Git worktree management
alias gwl="git worktree list"
alias gwp="git worktree prune"

# Derive a short tmux window name from the worktree directory name
# Usage: _tmux_window_name <dir_name>
_tmux_window_name() {
    local dir="$1"
    local name

    local sanitized="${dir//[^a-zA-Z0-9]/_}"
    if [[ ${#sanitized} -le 15 ]]; then
        name="$sanitized"
    else
        name="${sanitized: -15}"
    fi

    if [[ ${#name} -lt 2 ]]; then
        name="wt"
    fi

    echo "$name"
}

# Create a worktree with branch (shared logic for single and multi mode)
# Usage: _gwa_create_worktree <branch_name> <worktree_path> <base_ref>
_gwa_create_worktree() {
    local branch_name="$1"
    local worktree_path="$2"
    local base_ref="$3"

    if git show-ref --verify --quiet "refs/heads/$branch_name"; then
        printf "$MAGENTA_BACKGROUND%s$BOLD%s$NC$MAGENTA$BOLD%s$NC\n" "Creating worktree for " "existing local branch:" " $branch_name"
        git worktree add "$worktree_path" "$branch_name" || return 1
    elif git ls-remote --heads --quiet origin "$branch_name" 2>/dev/null | grep -q "refs/heads/$branch_name"; then
        printf "$MAGENTA_BACKGROUND%s$BOLD%s$NC$MAGENTA$BOLD%s$NC\n" "Creating worktree for " "existing remote branch:" " $branch_name"
        git fetch origin "${branch_name}:refs/remotes/origin/${branch_name}"
        git worktree add --track -b "$branch_name" "$worktree_path" "origin/$branch_name"
    else
        printf "$MAGENTA_BACKGROUND%s$BOLD%s$NC$MAGENTA$BOLD%s$NC\n" "Creating worktree for " "new branch:" " $branch_name"
        git worktree add -b "$branch_name" "$worktree_path" "$base_ref"
        (cd "$worktree_path" && git push -u origin "$branch_name" 2>/dev/null) || {
            printf "  Could not push to remote (offline or permission issue)\n"
        }
    fi
}

# Navigate to bare repo root if inside a worktree
_gwa_navigate_to_bare_root() {
    if [ -f "$(pwd)/.git" ]; then
        if grep -q "gitdir: .*/\.bare/worktrees/" "$(pwd)/.git" 2>/dev/null; then
            local bare_repo_root
            bare_repo_root="$(git rev-parse --git-common-dir 2>/dev/null)"
            bare_repo_root="$(cd "$(dirname "$bare_repo_root")" && pwd)"
            printf "%s$CYAN$BOLD%s$NC\n" "Navigating to bare repo root: " "$bare_repo_root"
            cd "$bare_repo_root" || return 1
        fi
    fi
}

# Single worktree mode (original gwa behavior)
_gwa_single() {
    local branch_name="$1"
    local local_worktree_path="$2"
    local no_tmux="$3"
    local base_ref="$4"

    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        printf "$RED$BOLD%s$NC\n\n" "Aborting: not in a bare git repository."
        return 1
    fi

    _gwa_navigate_to_bare_root || return 1

    printf "%s$CYAN$BOLD%s$NC\n" " Branch name: " "$branch_name"
    printf "%s$CYAN$BOLD%s$NC\n" " Worktree path: " "$local_worktree_path"

    _gwa_create_worktree "$branch_name" "$local_worktree_path" "$base_ref" || return 1

    if [[ "$no_tmux" == true ]]; then
        return 0
    fi

    if [[ -n "$TMUX" ]]; then
        local open_window="n"
        printf "$CYAN_BACKGROUND%s$NC " " Open new tmux window? [y/N]:"
        read -r open_window
        if [[ "$open_window" != [yY] ]]; then
            return 0
        fi

        local window_name
        window_name=$(_tmux_window_name "$(basename "$local_worktree_path")")

        if tmux list-windows -F '#{window_name}' | grep -q "^${window_name}$"; then
            printf "$YELLOW%s$NC $BOLD%s$NC\n" " Note:" "Tmux window '$window_name' already exists"
        else
            local full_worktree_path
            full_worktree_path="$(cd "$(dirname "$local_worktree_path")" 2>/dev/null && pwd)/$(basename "$local_worktree_path")"
            tmux new-window -n "$window_name" -c "$full_worktree_path" "[[ -f package.json ]] && printf \"\n$CYAN%s$NC\n\n\" \"  Install NPM dependencies in fresh worktrees\"; exec $SHELL"
            printf "$GREEN%s$BOLD$NC%s%s\n" " Opened tmux window: " "$window_name -> $local_worktree_path"
        fi
    fi
}

# Create worktrees from a bare repository
gwa() {
    if [[ $# -eq 0 ]]; then
        cat <<EOF
${CYAN}Usage:${NC} gwa <branch_name> [local_worktree_path] [--count INT] [--start INT] [--base REF] [--no-tmux]

${BOLD}Create git worktrees from a bare repository.${NC}

${CYAN}Single worktree:${NC}
  gwa feature/login
  gwa feature/login my-dir

${CYAN}Multiple worktrees:${NC}
  gwa feature/auth --count 3
  gwa feature/auth --count 2 --start 5 --base develop

Run ${BOLD}gwa --help${NC} for full details.
EOF
        return 1
    fi

    local branch_name=""
    local local_worktree_path=""
    local count=""
    local start=""
    local base=""
    local no_tmux=false
    local positional=()

    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                cat <<EOF
${CYAN}Usage:${NC} gwa <branch_name> [local_worktree_path] [--count INT] [--start INT] [--base REF] [--no-tmux]

${BOLD}Create git worktrees from a bare repository.${NC}

${CYAN}Positional:${NC}
  branch_name            Branch to create/checkout
  local_worktree_path    Directory name (default: sanitized branch name)

${CYAN}Options:${NC}
  -b, --base <ref>       Base branch for new worktrees (default: auto-detected via _mb)
  -c, --count <n>        Create multiple worktrees with -pt{N} suffixes
  -s, --start <n>        Starting index for suffixes (default: 1)
  -n, --no-tmux          Skip tmux window creation
  -h, --help             Show this help message

${CYAN}Single worktree:${NC}
  gwa feature/login                     Create worktree for feature/login
  gwa feature/login my-dir              Create worktree at ./my-dir
  gwa feature/login --no-tmux           Skip the tmux prompt
  gwa feature/login --base develop      Branch from origin/develop

${CYAN}Multiple worktrees (branches from origin/main):${NC}
  gwa feature/auth --count 3            Creates -pt1, -pt2, -pt3
  gwa feature/auth --count 2 --start 5  Creates -pt5, -pt6
  gwa feature/auth --count 2 --base release/v2
EOF
                return 0
                ;;
            -c|--count)
                count="$2"
                shift 2
                ;;
            -s|--start)
                start="$2"
                shift 2
                ;;
            -n|--no-tmux)
                no_tmux=true
                shift
                ;;
            -b|--base)
                base="$2"
                shift 2
                ;;
            -*)
                printf "$RED%s$NC\n" "Unknown option: $1"
                return 1
                ;;
            *)
                positional+=("$1")
                shift
                ;;
        esac
    done

    branch_name="${positional[1]:-}"
    local_worktree_path="${positional[2]:-}"

    if [[ -z "$branch_name" ]]; then
        printf "$RED$BOLD%s$NC%s\n" "Error:" " branch name is required"
        return 1
    fi

    # Resolve base_ref: explicit --base flag, or auto-detect via _mb()
    local base_ref=""
    if [[ -n "$base" ]]; then
        base_ref="origin/$base"
    else
        local main_branch
        main_branch=$(_mb)
        if [[ "$main_branch" == "not found" ]] || [[ -z "$main_branch" ]]; then
            printf "$RED$BOLD%s$NC%s\n" "Error:" " Could not detect default branch"
            return 1
        fi
        base_ref="origin/$main_branch"
    fi

    printf "$CYAN%s$NC $BOLD%s$NC\n" "Base ref:" "$base_ref"
    printf "$MAGENTA%s$NC\n" "Fetching latest ${base_ref}..."
    git fetch origin "${base_ref#origin/}:refs/remotes/${base_ref}" 2>/dev/null || true

    if [[ -n "$count" ]]; then
        if ! [[ "$count" =~ ^[0-9]+$ ]] || [[ "$count" -lt 1 ]]; then
            printf "$RED$BOLD%s$NC%s\n" "Error:" " --count must be a positive integer"
            return 1
        fi
        if [[ -n "$start" ]] && ! [[ "$start" =~ ^[0-9]+$ ]]; then
            printf "$RED$BOLD%s$NC%s\n" "Error:" " --start must be a non-negative integer"
            return 1
        fi
        if [[ -n "$local_worktree_path" ]]; then
            printf "$YELLOW%s$NC%s\n" " Warning:" " local_worktree_path is ignored with --count"
        fi
        [[ -z "$start" ]] && start=1

        local end_index=$((start + count - 1))
        printf "\n$CYAN_BACKGROUND%s$NC\n" " Creating $count worktrees "
        printf "$CYAN%s$NC%s\n\n" " Branches:" " ${branch_name}-pt${start} through ${branch_name}-pt${end_index}"

        local worktree_paths=()
        local window_names=()

        for ((i = start; i <= end_index; i++)); do
            local full_branch="${branch_name}-pt${i}"
            local worktree_path="${full_branch//[^a-zA-Z0-9._-]/_}"

            printf "$MAGENTA_BACKGROUND%s$NC %s$BOLD%s$NC\n" " [$((i - start + 1))/$count] " "Creating: " "$full_branch"

            if _gwa_single "$full_branch" "$worktree_path" true "$base_ref"; then
                worktree_paths+=("$worktree_path")
                window_names+=("$(_tmux_window_name "$(basename "$worktree_path")")")
                printf "  $GREEN%s$NC %s$BOLD%s$NC\n\n" "" "Worktree created at: " "$worktree_path"
            else
                printf "  $RED%s$NC\n\n" "Failed to create worktree for $full_branch"
            fi
        done

        # Batch-create tmux windows
        if [[ "$no_tmux" != true ]] && [[ -n "$TMUX" ]] && [[ ${#worktree_paths[@]} -gt 0 ]]; then
            printf "$CYAN_BACKGROUND%s$NC\n\n" " Creating tmux windows "
            local base_dir
            base_dir=$(pwd)

            for ((i = 1; i <= ${#worktree_paths[@]}; i++)); do
                local wt_path="${worktree_paths[$i]}"
                local win_name="${window_names[$i]}"
                local full_path="$base_dir/$wt_path"

                if tmux list-windows -F '#{window_name}' | grep -q "^${win_name}$"; then
                    printf "$YELLOW%s$NC $BOLD%s$NC\n" " Note:" "Tmux window '$win_name' already exists"
                else
                    printf "  %s$BOLD%s$NC%s%s\n" "Creating tmux window: " "$win_name" " -> " "$full_path"
                    tmux new-window -n "$win_name" -c "$full_path" "[[ -f package.json ]] && printf \"\n$CYAN%s$NC\n\n\" \"  Install NPM dependencies in fresh worktrees\"; exec $SHELL"
                fi
            done

            printf "\n$GREEN%s$NC%s\n" "" " Created ${#worktree_paths[@]} tmux windows"
        elif [[ "$no_tmux" != true ]] && [[ -z "$TMUX" ]]; then
            printf "$YELLOW_BACKGROUND%s$NC%s\n" " Warning " " Not inside tmux session. Skipping tmux window creation."
        fi

        printf "\n$CYAN_BACKGROUND%s$NC\n" " Done! "
        printf "$CYAN%s$NC\n" "Created ${#worktree_paths[@]} worktrees:"
        for wt in "${worktree_paths[@]}"; do
            printf "   %s\n" "$wt"
        done
        printf "\n%s$BOLD%s$NC%s$BOLD%s$NC%s\n" "Tip: Use " "gwl" " to list worktrees, " "gwr" " to remove them"
        printf "$CYAN%s$NC\n" "  Install NPM dependencies in fresh worktrees"
    else
        [[ -z "$local_worktree_path" ]] && local_worktree_path=${branch_name//[^a-zA-Z0-9._-]/_}
        _gwa_single "$branch_name" "$local_worktree_path" "$no_tmux" "$base_ref"
    fi
}

# Remove a single worktree (helper for gwr)
# Collects branch names into _gwr_local_branches / _gwr_upstream_branches
# Usage: _gwr_remove <worktree_path>
_gwr_remove() {
    local worktree_path="$1"

    if [[ -n "$TMUX" ]]; then
        local dir_name window_name
        dir_name=$(basename "$worktree_path")
        window_name=$(_tmux_window_name "$dir_name")
        if tmux list-windows -F '#{window_name}' | grep -q "^${window_name}$"; then
            tmux kill-window -t "$window_name"
            printf "$GREEN%s$NC%s\n" " Closed tmux window: " "$window_name"
        fi
    fi

    local branch_name upstream_branch
    branch_name=$(git -C "$worktree_path" rev-parse --abbrev-ref HEAD 2>/dev/null)
    upstream_branch=$(git -C "$worktree_path" rev-parse --abbrev-ref '@{upstream}' 2>/dev/null)

    local output
    if output=$(git worktree remove "$worktree_path" 2>&1); then
        printf "$GREEN%s$NC%s\n" " Removed worktree: " "$worktree_path"
    else
        printf "$RED%s$NC\n%s" "Failed to remove worktree" "$output"
        printf "\n\n$YELLOW_BACKGROUND%s$NC " " Force remove? Type 'yes' to confirm:"
        local force_remove
        read -r force_remove </dev/tty
        if [[ "$force_remove" == "yes" ]]; then
            git worktree remove --force "$worktree_path"
            printf "$GREEN%s$NC%s\n" " Removed worktree (forced): " "$worktree_path"
        else
            return 1
        fi
    fi

    [[ -n "$branch_name" ]] && _gwr_local_branches+=("$branch_name")
    [[ -n "$upstream_branch" ]] && _gwr_upstream_branches+=("$upstream_branch")
}

# Prompt to delete all branches collected by _gwr_remove
_gwr_cleanup_branches() {
    if [[ ${#_gwr_local_branches[@]} -eq 0 ]]; then
        return 0
    fi

    printf "\n$CYAN$BOLD%s$NC\n" "  The following git branches still exist"
    for i in {1..${#_gwr_local_branches[@]}}; do
        printf "$CYAN%s$NC%s" "local:    " "${_gwr_local_branches[$i]}"
        if [[ -n "${_gwr_upstream_branches[$i]}" ]]; then
            printf "$CYAN%s$NC%s" "  remote: " "${_gwr_upstream_branches[$i]}"
        fi
        printf "\n"
    done

    printf "\n$YELLOW_BACKGROUND%s$NC " " Delete these branches? Type 'yes' to confirm:"
    local confirm
    read -r confirm </dev/tty
    if [[ "$confirm" == "yes" ]]; then
        for i in {1..${#_gwr_local_branches[@]}}; do
            git branch -D "${_gwr_local_branches[$i]}" && \
                printf "$GREEN%s$NC%s\n" " Deleted local branch: " "${_gwr_local_branches[$i]}"
            if [[ -n "${_gwr_upstream_branches[$i]}" ]]; then
                local remote_branch="${_gwr_upstream_branches[$i]#origin/}"
                git push origin ":$remote_branch" 2>/dev/null && \
                    printf "$GREEN%s$NC%s\n" " Deleted remote branch: " "${_gwr_upstream_branches[$i]}"
            fi
        done
    fi
}

# Remove worktree(s) — supports fzf multi-select
gwr() {
  # Resolve path argument to absolute before _gwa_navigate_to_bare_root may cd
  local resolved_path
  [[ $# -gt 0 ]] && resolved_path="$(cd "$1" 2>/dev/null && pwd || echo "$1")"

  _gwa_navigate_to_bare_root || return 1

  _gwr_local_branches=()
  _gwr_upstream_branches=()

  if [ $# -eq 0 ]; then
    # Interactive multi-selection with fzf
    local selected
    selected=$(git worktree list --porcelain | grep "^worktree" | cut -d' ' -f2 | grep -v '/\.' | fzf --multi --prompt="Select worktree(s) to remove (TAB to multi-select): ")
    if [ -z "$selected" ]; then
      return 0
    fi

    while IFS= read -r worktree_path; do
        printf "\n$MAGENTA_BACKGROUND%s$NC\n" " Removing: $worktree_path "
        _gwr_remove "$worktree_path"
    done <<< "$selected"
  else
    _gwr_remove "$resolved_path"
  fi

  _gwr_cleanup_branches
}

# Switch to worktree (tmux window if in tmux, cd otherwise)
gws() {
    local worktree_path
    worktree_path=$(git worktree list --porcelain | grep "^worktree" | cut -d' ' -f2 | fzf --prompt="Switch to worktree: " --preview "ls -la {}")
    [[ -z "$worktree_path" ]] && return 0

    # Fall back to cd if not in tmux or --no-tmux passed
    if [[ -z "$TMUX" || "$1" == "--no-tmux" ]]; then
        cd "$worktree_path" || return 1
        return 0
    fi

    local dir_name window_name
    dir_name=$(basename "$worktree_path")
    window_name=$(_tmux_window_name "$dir_name")

    if tmux list-windows -F '#{window_name}' | grep -q "^${window_name}$"; then
        tmux select-window -t "$window_name"
        printf "  ${GREEN}%s${NC} %s${BOLD}%s${NC}\n" "↪" "Switched to existing window: " "$window_name"
    else
        tmux new-window -n "$window_name" -c "$worktree_path"
        printf "  ${GREEN}%s${NC} %s${BOLD}%s${NC}%s%s\n" "" "Opened new tmux window: " "$window_name" " -> " "$worktree_path"
    fi
}

# Open existing worktrees in tmux windows using fzf multiselect
gwo() {
    if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
        cat <<EOF
${CYAN}Usage:${NC} gwo

${BOLD}Opens existing git worktrees in tmux windows using fzf multiselect.${NC}

${CYAN}Controls:${NC}
  TAB          Select/deselect worktree
  ENTER        Open selected worktrees in tmux windows
  ESC          Cancel

${CYAN}Window naming:${NC}
   Window names are derived from directory names: sanitized, last 15 chars, min 2 chars

EOF
        return 0
    fi

    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        printf "$RED$BOLD%s$NC%s\n" "Error:" " Not in a git repository"
        return 1
    fi

    if [[ -z "$TMUX" ]]; then
        printf "$RED$BOLD%s$NC%s\n" "Error:" " Not inside a tmux session"
        return 1
    fi

    if ! command -v fzf &> /dev/null; then
        printf "$RED$BOLD%s$NC%s\n" "Error:" " fzf is not installed"
        return 1
    fi

    local worktrees
    worktrees=$(git worktree list | grep -v '(bare)')

    if [[ -z "$worktrees" ]]; then
        printf "$YELLOW_BACKGROUND%s$NC\n" " No worktrees found "
        printf "$CYAN%s$NC\n" "Use 'gwa <branch-name>' to create worktrees."
        return 0
    fi

    local selected
    selected=$(echo "$worktrees" | fzf --multi \
        --prompt="Select worktrees (TAB to select, ENTER to confirm): " \
        --preview="ls -la {1}" \
        --preview-window=right:40%)

    if [[ -z "$selected" ]]; then
        printf "$CYAN%s$NC\n" "No worktrees selected."
        return 0
    fi

    local count=0
    local skipped=0

    printf "\n$CYAN_BACKGROUND%s$NC\n\n" " Opening worktrees "

    while IFS= read -r line; do
        local worktree_path
        local branch_name
        local window_name

        worktree_path=$(echo "$line" | awk '{print $1}')
        branch_name=$(echo "$line" | grep -o '\[.*\]' | tr -d '[]')

        local dir_name
        dir_name=$(basename "$worktree_path")

        window_name=$(_tmux_window_name "$dir_name")

        if tmux list-windows -F '#{window_name}' | grep -q "^${window_name}$"; then
            printf "  $YELLOW%s$NC %s$BOLD%s$NC%s\n" "Skipping:" "TMUX window '" "$window_name" "' already exists"
            ((skipped++))
            continue
        fi

        tmux new-window -n "$window_name" -c "$worktree_path" "[[ -f package.json ]] && printf \"\n$CYAN%s$NC\n\n\" \"  Install NPM dependencies in fresh worktrees\"; exec $SHELL"

        printf "  $GREEN%s$NC %s$BOLD%s$NC%s%s\n" "" "Opened " "$window_name" " -> " "$worktree_path"
        ((count++))
    done <<< "$selected"

    printf "\n$CYAN_BACKGROUND%s$NC" " Done "
    if [[ $count -gt 0 ]]; then
        printf " %s$BOLD%s$NC%s" "Opened " "$count" " worktree(s)"
    fi
    if [[ $skipped -gt 0 ]]; then
        printf " (skipped %s existing)" "$skipped"
    fi
}
