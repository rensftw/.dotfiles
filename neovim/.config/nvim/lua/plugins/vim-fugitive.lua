return {
    'tpope/vim-fugitive',
    lazy = true,
    event = 'VeryLazy',
    keys = {
        { mode = { 'n' }, '<leader>gg',   ':Git<CR>', },
        { mode = { 'n' }, '<leader>gbb',  ':GBrowse!<CR>', },
        { mode = { 'v' }, '<leader>gbb',  ":'<,'>GBrowse<CR>", },
        -- See blame history for the current file
        { mode = { 'n' }, '<leader>gbf',  ':Git blame<CR>', },
        -- Show git history for the current line
        { mode = { 'n' }, '<leader>gbl',  ':GitBlameLine<CR>', },
        -- Show git commit log (better performance than :Gclog)
        { mode = { 'n' }, '<leader>gl',   ':Git log --oneline<CR>', },
        -- Open current file changes in a vertical split.
        -- This opens a 3-way diff if there are git conflict markers in the buffer.
        { mode = { 'n' }, '<leader>gds',  ':Gvdiffsplit!<cr>', },
        -- Compare current branch changes with main (populates quickfix list)
        -- Equivalent of `git diff origin/main...HEAD`
        -- Note the 3 dot notation - this means we are checking against the last common
        -- ancestor, so if main is ahead of the feature branch we don't include those
        -- new/unrelated changes in the comparison
        { mode = { 'n' }, '<leader>gdm',  ':Git difftool -y origin/main...<CR>', },

        -- Find out which commit renamed a file
        -- git log --follow --name-status path/to/file.js
        -- The `--name-status` flag shows:
        -- A for added files
        -- D for deleted files
        -- M for modified files
        -- R for renamed files (e.g. R080 for 80% similarity)

        -- Compare a file that was renamed (e.g. changed extensions between versions)
        -- git diff SOME_BRANCH:PATH_TO_OLD_FILENAME HEAD:PATH_TO_NEW_FILENAME
        -- Vanilla: git diff develop:path/to/component.js HEAD:path/to/components.tsx
        -- Use case with Fugitive:
        -- 1. Open the file we want to diff
        -- 2. Press <LEADER>p to copy the filepath
        -- 3. Run the Fugitive command with the base branch and make sure to update the extension in the pasted filepath, e.g.:
        -- :Gvdiffsplit develop:path/to/component.js

        -- Compare with any branch
        { mode = { 'n' }, '<leader>gd',   ':Git difftool -y', },
        -- Open file revision
        -- This also works with :Gvdiffsplit branch:%
        -- source: https://vi.stackexchange.com/questions/3746/how-do-i-open-a-file-from-another-git-branch
        { mode = { 'n' }, '<leader>gfr',  ':Gvsplit :%<Left><Left>', },
        -- Mnemonic: current branch commits
        { mode = { 'n' }, '<leader>gcbc', ':GitCurrentBranchCommits<CR>', },
        -- Mnemonic: am I behind origin main?
        { mode = { 'n' }, '<leader>ga',   ':GitAmIBehind<CR>', },
    },
    cmd ={
        'G',
        'Gdiffsplit',
        'Gvdiffsplit',
        'Gclog',
        'GBrowse',
    },
    dependencies = {
        'tpope/vim-rhubarb'
    },
    config = function()
        local helpers = require('core.helpers')

        -- Git show a commit using difftool
        vim.api.nvim_create_user_command('GitShowCommit', 'Git difftool -y <args>~ <args>', {})

        -- Mnemonic: current branch commits
        vim.api.nvim_create_user_command('GitCurrentBranchCommits', function()
            local currentBranch = helpers.getCurrentGitBranch()
            local baseBranch = helpers.getBaseGitBranch()

            -- 'git log origin/main..HEAD --oneline'
            local gitFugitiveCommand = 'Git log origin/' .. baseBranch .. '..' .. currentBranch .. ' --oneline'
            vim.api.nvim_command(gitFugitiveCommand)
        end, {})

        -- Mnemonic: am I behind origin main?
        vim.api.nvim_create_user_command('GitAmIBehind', function()
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
    end
}
