return {
    'sindrets/diffview.nvim',
    lazy = true,
    cmd = { 'DiffviewOpen', 'DiffviewClose', 'DiffviewFileHistory' },
    keys = {
        -- Mnemonic: git diff main. Base branch is auto-detected
        -- (mirrors the shell `_mb` alias — main → master → develop).
        -- Three-dot range honours the merge-base, so unrelated commits on the
        -- base don't pollute the review.
        -- --imply-local makes the right-hand side the working-tree
        -- buffer so LSP / treesitter / gitsigns attach during review.
        {
            mode = { 'n' },
            '<leader>gdm',
            function()
                local base = require('core.helpers').getBaseGitBranch()
                if base == '' or base == 'not found' then
                    vim.notify(
                        'diffview: could not detect base branch (main/master/develop)',
                        vim.log.levels.WARN
                    )
                    return
                end
                vim.cmd('DiffviewOpen origin/' .. base .. '...HEAD --imply-local')
            end,
            desc = 'PR review vs base branch',
        },
        -- Mnemonic: git diff. Compare against any branch
        -- Use fzf-lua branches picker to avoid "typing" into cmdline which triggers
        -- blink.cmp's `cmdline` source, which calls diffview's broken
        -- completer (E5108 "too many results to unpack" on bare repos —
        -- diffview spreads ref-candidates via unpack() and exceeds
        -- LuaJIT's arg limit).
        {
            mode = { 'n' },
            '<leader>gd',
            function()
                require('fzf-lua').git_branches({
                    -- Scope to local branches only (`refs/heads`). The monorepo
                    -- uses a bare, blobless, single-branch worktree clone (see
                    -- system/.aliases.d/40-git-worktrees.sh): `refs/remotes`
                    -- accumulates thousands of *loose* remote-tracking refs from
                    -- incremental fetches, and enumerating + date-sorting those
                    -- (a stat() storm, no commit-graph) is what made this slow.
                    -- PR review here targets worktree branches, which live in
                    -- refs/heads — a handful, so this is instant. The base branch
                    -- has its own mapping (<leader>gdm). `refname:short` yields
                    -- clean refs (`main`), so the selection just needs a trim.
                    cmd = 'git for-each-ref --sort=-committerdate '
                        .. '--format="%(refname:short)" refs/heads',
                    -- Cap the preview at 20 commits. The fzf-lua default is an
                    -- unbounded `git log --graph` that re-walks full history on
                    -- every cursor move — the picker's main source of lag.
                    preview = 'git log --graph --pretty=oneline --abbrev-commit '
                        .. '--color -n 20 {1}',
                    actions = {
                        ['default'] = function(selected)
                            local branch = vim.trim(selected[1])
                            if branch == '' then return end
                            vim.cmd('DiffviewOpen ' .. branch .. '...HEAD --imply-local')
                        end,
                    },
                })
            end,
            desc = 'PR review vs <branch>',
        },
    },
    dependencies = {
        'nvim-lua/plenary.nvim',
        -- Loads mini.icons first so its `mock_nvim_web_devicons()` runs
        -- before diffview's icons-availability check fires.
        'nvim-mini/mini.icons',
    },
    opts = function()
        local actions = require('diffview.actions')

        local nav_keys = {
            { 'n', '<C-j>',     actions.select_next_entry, { desc = 'Open the diff for the next file' } },
            { 'n', '<C-k>',     actions.select_prev_entry, { desc = 'Open the diff for the previous file' } },
            { 'n', '<leader>e', actions.toggle_files,      { desc = 'Toggle the file panel' } },
            { 'n', 'q',         '<Cmd>DiffviewClose<CR>',  { desc = 'Close diffview tab' } },
        }

        return {
            signs = {
                fold_closed = ' ',
                fold_open  = ' ',
            },
            keymaps = {
                view               = nav_keys,
                file_panel         = nav_keys,
                file_history_panel = nav_keys,
            },
        }
    end,
}
