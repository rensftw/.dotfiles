local M = {}

-- Virtual text helper logic
local Virtual_text = {}
Virtual_text.show = false
Virtual_text.toggle = function()
    Virtual_text.show = not Virtual_text.show
    vim.diagnostic.config({
        virtual_text = Virtual_text.show,
        underline = Virtual_text.show,
    })
end

-- Git helpers
local function getCurrentGitBranch()
    local gitCommand = 'git rev-parse --abbrev-ref HEAD'
    local handle = io.popen(gitCommand)
    local result = handle:read('*a')
    handle:close()
    return result:sub(1, -2) -- Remove trailing newline character
end

local function getBaseGitBranch()
    -- Mirror the shell `_mb` helper (system/.aliases.d/20-git-helpers.sh):
    -- EXACT-match the candidate names so a branch merely *containing* one of
    -- them (e.g. `maintenance`, `domain`, `main-backup`) is never mistaken for
    -- the base branch. Falls back to the symbolic HEAD for bare repos.
    local gitCommand = [=[
        branches=$(git branch --format='%(refname:short)' 2>/dev/null)
        for name in main master develop; do
            if printf '%s\n' "$branches" | grep -qx "$name"; then
                printf '%s\n' "$name"
                exit 0
            fi
        done
        head_branch=$(git symbolic-ref --short HEAD 2>/dev/null)
        case "$head_branch" in
            main|master|develop) printf '%s\n' "$head_branch"; exit 0 ;;
        esac
        printf '%s\n' "not found"
    ]=]
    local handle = io.popen(gitCommand)
    local result = handle:read('*a')
    handle:close()
    return result:sub(1, -2) -- Remove trailing newline character
end

-- Export all helpers
M.Virtual_text = Virtual_text
M.getCurrentGitBranch = getCurrentGitBranch
M.getBaseGitBranch = getBaseGitBranch
return M
