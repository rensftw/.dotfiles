################################################################################
# Git helper functions
# Loaded before workflow and worktree modules that depend on these
################################################################################

# For more fzf + git inspiration checkout: https://junegunn.kr/2016/07/fzf-git/, https://gist.github.com/junegunn/8b572b8d4b5eddd8b85e5f4d40f17236
is_in_git_repo() {
  git rev-parse HEAD > /dev/null 2>&1
}

fzf-down() {
  fzf --height 50% "$@" --border
}

# Collect candidate files robustly (handles spaces, renames, etc.)
gsp() {
  is_in_git_repo || return
  git status --porcelain |
  fzf-down --ansi --multi --tac |
  # clean up git status symbols for added, modified, renamed etc (A, M, D, ??)
  sed 's/^.. //; s/.* -> //'
}

# Is the base branch main or master?
_mb() {
    local branches
    branches=$(git branch --format='%(refname:short)' 2>/dev/null)
    local name
    for name in main master develop; do
        if echo "$branches" | grep -qx "$name"; then
            echo "$name"
            return
        fi
    done

    # Bare repo fallback: HEAD still points to default branch name
    local head_branch
    head_branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    case "$head_branch" in
        main|master|develop) echo "$head_branch"; return ;;
    esac

    echo 'not found'
}

# Git branch with commit log preview
_gb() {
  is_in_git_repo || return
  git branch --color=always | grep -v '/HEAD\s' | sort |
  fzf-down --ansi --multi --tac --preview-window right:50% \
    --preview "git log --oneline --graph --date=short --color=always --pretty='format:%C(auto)%cd %h%d %s' \$(sed s/^..// <<< {} | cut -d' ' -f1)" |
  sed 's/^..//' | cut -d' ' -f1 |
  sed 's#^remotes/##'
}
