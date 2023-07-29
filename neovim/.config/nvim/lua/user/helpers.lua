local M = {}

-- Virtual text helper logic
Virtual_text = {}
Virtual_text.show = true
Virtual_text.toggle = function()
    Virtual_text.show = not Virtual_text.show
    vim.diagnostic.config({
        virtual_text = Virtual_text.show,
        underline = Virtual_text.show,
        update_in_insert = true,
        severity_sort = true,
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
    local gitCommand = [=[
        _mb() {
            BRANCHES=$(git branch)
            if [[ $BRANCHES =~ 'main' ]]; then
                echo 'main'
            elif [[ $BRANCHES =~ 'master' ]]; then
                echo 'master'
            elif [[ $BRANCHES =~ 'develop' ]]; then
                echo 'develop'
            else
                echo 'not found'
            fi
        }
        _mb
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
