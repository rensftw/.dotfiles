local helpers = require('user.helpers')

-- Write all changes to modified buffers,
-- close all buffers except the active one,
-- and return focus to the same spot it was initially
vim.api.nvim_create_user_command('BufOnly', 'wa | %bdelete | edit # | bdelete # | normal `"', {})

-- Git show a commit using difftool
vim.api.nvim_create_user_command('GitShowCommit', 'Git difftool -y <args>~ <args>', {})

-- Mnemonic: current branch commits
vim.api.nvim_create_user_command('GitCurrentBranchCommits', function ()
    local currentBranch = helpers.getCurrentGitBranch()
    local baseBranch = helpers.getBaseGitBranch()

    -- 'git log origin/main..HEAD --oneline'
    local gitFugitiveCommand = 'Git log origin/' .. baseBranch .. '..' .. currentBranch .. ' --oneline'
    vim.api.nvim_command(gitFugitiveCommand)
end, {})

-- Mnemonic: am I behind origin main?
vim.api.nvim_create_user_command('GitAmIBehind', function ()
    local currentBranch = helpers.getCurrentGitBranch()
    local baseBranch = helpers.getBaseGitBranch()

    --  'git log HEAD..origin/main --oneline'
    local gitFugitiveCommand = 'Git log ' .. currentBranch .. '..' .. 'origin/' .. baseBranch .. ' --oneline'
    vim.api.nvim_command(gitFugitiveCommand)
end, {})

-- Show git commit history for the current line
vim.api.nvim_create_user_command('GitBlameLine', function()
    local filePath = vim.api.nvim_buf_get_name(0)
    local lineNumber = vim.api.nvim_win_get_cursor(0)[1]

    -- Git command to show history of a specific line
    -- https://stackoverflow.com/questions/50469927/view-git-history-of-specific-line
    -- e.g. git log -L15,+1:'path/to/your/file.txt'
    local gitFugitiveCommand = ":G log -L" .. lineNumber .. ",+1:" .. "'" .. filePath .. "'"
    vim.api.nvim_command(gitFugitiveCommand)
end, {})

