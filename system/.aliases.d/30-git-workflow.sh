################################################################################
# Git workflow aliases and functions
# Depends on: 20-git-helpers.sh (is_in_git_repo, fzf-down, _mb, _gb)
################################################################################

# Git log with commit preview
gl() {
  is_in_git_repo || return
  git log --date=short --format="%C(green)%C(bold)%cd %C(auto)%h%d %s (%an)" --graph --color=always |
  fzf-down --ansi --no-sort --reverse --multi --bind 'ctrl-s:toggle-sort' \
    --header 'Press CTRL-S to toggle sort' \
    --preview 'grep -o "[a-f0-9]\{7,\}" <<< {} | xargs git show --color=always' |
  grep -o "[a-f0-9]\{7,\}"
}

# Git stash with preview
gstash() {
  is_in_git_repo || return
  git stash list | fzf-down --reverse -d: --preview 'git show --color=always {1}' |
  cut -d: -f1
}

# Export git stash changes to a patchfile
# source: https://stackoverflow.com/questions/3973034/export-a-stash-to-another-computer
export-stash() {
    local STASH_ENTRY
    STASH_ENTRY=$(gstash)
    git stash show "$STASH_ENTRY" -p > changes.patch
}

# Mnemonic: git checkout branch
gcb() {
  git checkout $(_gb)
}

# Mnemonic: git branch delete
gbd() {
  git branch -D $(_gb)
}

# Interactive FZF prompt to remove changes
gc() {
  local files=$(gsp)
  [[ -z "$files" ]] && return 0
  git checkout $files
}

# Interactive FZF prompt to stage files
ga() {
  local files=$(gsp)
  [[ -z "$files" ]] && return 0
  git add $files
}

# Interactive FZF prompt to stage chunks
gap() {
  local files=$(gsp)
  [[ -z "$files" ]] && return 0
  git add -p $files
}

# Interactive FZF prompt to unstage files
gr() {
  local files=$(gsp)
  [[ -z "$files" ]] && return 0
  git reset $files
}

# Mnemonic: git stash apply
gsa() {
  local entry=$(gstash)
  [[ -z "$entry" ]] && return 0
  git stash apply $entry
}

# Mnemonic: current branch commits
cbcommits() {
  local MAIN_BRANCH CURRENT_BRANCH
  MAIN_BRANCH=$(_mb)
  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

  git log origin/"$MAIN_BRANCH".."$CURRENT_BRANCH" --oneline
}

# Mnemonic: Am I behind origin/main?
amibehind() {
  local MAIN_BRANCH CURRENT_BRANCH
  MAIN_BRANCH=$(_mb)
  CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

  git log "$CURRENT_BRANCH"..origin/"$MAIN_BRANCH" --oneline
}

# What has happened to origin/main since I last pulled? (shows commits)
glmomo() {
  local MAIN_BRANCH
  MAIN_BRANCH=$(_mb)

  git log "$MAIN_BRANCH"..origin/"$MAIN_BRANCH" --date=short --format="%C(green)%C(bold)%cd %C(auto)%h%d %s (%C(cyan)%C(bold)%an%C(auto))" --color=always
}

# What has happened to origin/main since I last pulled? (shows file changes)
gdmomo() {
  local MAIN_BRANCH
  MAIN_BRANCH=$(_mb)
  git diff "$MAIN_BRANCH"...origin/"$MAIN_BRANCH" --compact-summary
}

# Show git status
alias gs="git status"

# List local branches
alias gb="git branch"

# Show a compact summary of unstaged changes
alias gdc="git diff --compact-summary"

# Delete all local branches except main/master and the branch I'm currently on
alias gdab='git branch | grep -Ev "(master|main|develop|\*)" | xargs git branch -D'

# Fetch
gf() {
    git fetch origin "$(git branch --show-current)"
}

# Fetch and show status
alias gfs="git fetch && git status"

# Pretty log
alias glg="git log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(bold yellow)%d%C(reset)'"

# Diff
alias gd="git diff"
alias gds="git diff --staged"
