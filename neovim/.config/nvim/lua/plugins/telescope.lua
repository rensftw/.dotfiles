return {
    'nvim-telescope/telescope.nvim',
    lazy = true,
    dependencies = {
        'nvim-lua/plenary.nvim',
        { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
        'nvim-telescope/telescope-ui-select.nvim'
    },
    cmd = { 'Telescope' },
    keys = function()
        local telescope = require('telescope.builtin');

        return {
            { mode = { 'n' }, '<leader>o',  function() telescope.find_files({ hidden = true, previewer = false }) end },
            { mode = { 'n' }, '<leader>i',  telescope.resume },
            { mode = { 'n' }, '<leader>.',  function() telescope.find_files({ cwd = '$HOME/.dotfiles', hidden = true }) end },
            { mode = { 'n' }, '<leader>fb', telescope.current_buffer_fuzzy_find },
            { mode = { 'n' }, '<leader>ff', telescope.live_grep },
            {
                mode = { 'n' },
                '<leader>fa',
                function()
                    telescope.grep_string({
                        search = vim.fn.input('   filter grep ❯ '),
                        initial_mode = 'normal'
                    })
                end
            },
            {
                mode = { 'n' },
                '<leader>fw',
                function()
                    telescope.grep_string({
                        search = vim.fn.expand('<cword>'), initial_mode = 'normal' })
                end
            },
            { mode = { 'n' }, '<leader>b',  function() telescope.buffers({initial_mode = 'normal'}) end},
            { mode = { 'n' }, '<leader>?',  telescope.help_tags},
            { mode = { 'n' }, '<leader>m',  telescope.man_pages},
            { mode = { 'n' }, '<leader>:',  telescope.commands},
            { mode = { 'n' }, '<leader>gs', function() telescope.git_status({initial_mode = 'normal'}) end},
            -- Mnemonic: git checkout branch
            {
                mode = { 'n' },
                '<leader>gcbb',
                function()
                telescope.git_branches({initial_mode = 'normal', show_remote_tracking_branches = false})
                end
            },
        }
    end,
    config = function()
        local telescope = require('telescope');
        local actions = require('telescope.actions');
        local action_state = require('telescope.actions.state')

        local custom_actions = {}

        function custom_actions.quickfix_list_mutliselect_and_auto_open(prompt_bufnr)
            actions.smart_send_to_qflist(prompt_bufnr)
            actions.open_qflist(prompt_bufnr)
        end

        telescope.setup {
            defaults = {
                mappings = {
                    n = {
                        ['dd'] = actions.delete_buffer,
                        ['<c-q>'] = custom_actions.quickfix_list_mutliselect_and_auto_open,
                        -- center results
                        ['<CR>'] = actions.select_default + actions.center,
                        ['<c-t>'] = actions.file_tab + actions.center,
                        ['<c-v>'] = actions.file_vsplit + actions.center,
                        ['<c-x>'] = actions.file_split + actions.center,
                    },
                    i = {
                        ['<c-d>'] = actions.delete_buffer,
                        ['<c-q>'] = custom_actions.quickfix_list_mutliselect_and_auto_open,
                        -- center results
                        ['<CR>'] = actions.select_default + actions.center,
                        ['<c-t>'] = actions.file_tab + actions.center,
                        ['<c-v>'] = actions.file_vsplit + actions.center,
                        ['<c-x>'] = actions.file_split + actions.center,
                    }
                },
                vimgrep_arguments = {
                    'rg',
                    '--hidden',
                    '--color=never',
                    '--no-heading',
                    '--with-filename',
                    '--line-number',
                    '--column',
                    '--smart-case',
                    '--trim'
                },
                file_ignore_patterns = {
                    '.git/',
                    'node_modules/',
                    'tags'
                },
                prompt_prefix = '   ',
                selection_caret = '❯ ',
                selection_strategy = 'reset',
                sorting_strategy = 'ascending',
                scroll_strategy = 'cycle',
                color_devicons = true,
                layout_strategy = 'horizontal',
                layout_config = {
                    prompt_position = 'top',
                    width = 0.8,
                    height = 0.85,
                    preview_cutoff = 120,

                    horizontal = {
                        preview_width = 0.5,
                    },

                    vertical = {
                        width = 0.9,
                        height = 0.95,
                        preview_height = 0.5,
                    },

                    flex = {
                        horizontal = {
                            preview_width = 0.9,
                        },
                    },
                },
            },
            pickers = {
                find_files = {
                    find_command = { 'fd', '--type', 'f', '--strip-cwd-prefix' }
                }
            }
        }

        telescope.load_extension('fzf')
        telescope.load_extension('ui-select')
    end
}
