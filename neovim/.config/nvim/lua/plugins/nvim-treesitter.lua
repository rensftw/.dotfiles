return {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    event = { 'BufReadPost', 'BufNewFile' },
    keys = {
        { '<c-a>', desc = 'Begin selection' },
        { '<c-s>', desc = 'Increment selection by scope' },
        { '<c-d>', desc = 'Decrement selection' },
    },
    dependencies = {
        'nvim-treesitter/nvim-treesitter-textobjects',
        'nvim-treesitter/nvim-treesitter-context',
    },
    config = function()
        require 'nvim-treesitter.configs'.setup({
            ensure_installed = {
                'bash',
                'c',
                'cmake',
                'comment',
                'cpp',
                'css',
                'dockerfile',
                'go',
                'graphql',
                'vimdoc',
                'html',
                'http',
                'javascript',
                'jsdoc',
                'json',
                'jsonc',
                'latex',
                'lua',
                'make',
                'markdown', --experimental
                'pug',
                'python',
                'regex',
                'ruby',
                'rust',
                'scss',
                'svelte',
                'toml',
                'tsx',
                'typescript',
                'vim',
                'vue',
                'yaml',
            },
            highlight = { enable = true },
            indent = { enable = true },
            incremental_selection = {
                enable = true,
                keymaps = {
                    init_selection = '<c-a>',
                    node_incremental = '<c-a>',
                    scope_incremental = '<c-s>',
                    node_decremental = '<c-d>',
                },
            },
            textobjects = {
                select = {
                    enable = true,
                    lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
                    keymaps = {
                        -- You can use the capture groups defined in textobjects.scm
                        ['aa'] = '@parameter.outer',
                        ['ia'] = '@parameter.inner',
                        ['af'] = '@function.outer',
                        ['if'] = '@function.inner',
                        ['ac'] = '@class.outer',
                        ['ic'] = '@class.inner',
                    },
                },
                move = {
                    enable = true,
                    set_jumps = true, -- whether to set jumps in the jumplist
                    goto_next_start = {
                        [']f'] = '@function.outer',
                        [']c'] = '@class.outer',
                    },
                    goto_next_end = {
                        [']F'] = '@function.outer',
                        [']C'] = '@class.outer',
                    },
                    goto_previous_start = {
                        ['[f'] = '@function.outer',
                        ['[c'] = '@class.outer',
                    },
                    goto_previous_end = {
                        ['[F'] = '@function.outer',
                        ['[C'] = '@class.outer',
                    },
                },
                -- swap = {
                --     enable = true,
                --     swap_next = {
                --         ['<leader>s'] = '@parameter.inner',
                --     },
                --     swap_previous = {
                --         ['<leader>S'] = '@parameter.inner',
                --     },
                -- },
            }
        })

        require 'treesitter-context'.setup()

        -- Folds: Prefer to use foldmethod treesitter.foldexpr when availabe
        -- Fallback to foldmethod indent (see neovim/.config/nvim/lua/core/options.lua)

        -- Fix 'No fold found error' with Telescope + Treesitter
        -- https://github.com/nvim-telescope/telescope.nvim/issues/699#issuecomment-1159637962
        vim.api.nvim_create_autocmd({ 'BufEnter', 'BufNew', 'BufWinEnter' }, {
            group = vim.api.nvim_create_augroup('fix_foldexpr_treesitter_issue', {}),
            pattern = { '*' },
            callback = function()
                vim.cmd.normal('zx')
            end,
        })

        vim.opt.foldmethod = 'expr'
        vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
        -- source: https://github.com/abzcoding/lvim/blob/a4e400f0ffaba68377cca432566e54617dfeb2ca/lua/user/neovim.lua#L52
        vim.opt.foldtext =
        [[substitute(getline(v:foldstart),'\\t',repeat('\ ',&tabstop),'g').'  '.trim(getline(v:foldend)) . ' (' . (v:foldend - v:foldstart + 1) . ' lines)']]
        vim.opt.foldenable = false
    end
}
