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
                    cmd = 'git branch --all --color',
                    actions = {
                        ['default'] = function(selected)
                            -- Selection format: `* main`, `  feature-x`,
                            -- `  remotes/origin/main`, etc. Last whitespace-
                            -- delimited token is the ref; strip the
                            -- `remotes/` prefix that `git branch -a` adds.
                            local branch = selected[1]:match('[^ ]+$')
                            if not branch or branch == '' then return end
                            branch = branch:gsub('^remotes/', '')
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
