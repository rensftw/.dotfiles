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
        'JoosepAlviste/nvim-ts-context-commentstring',
    },
    config = function()
        require 'nvim-treesitter.configs'.setup({
            -- Install parsers synchronously (only applied to `ensure_installed`)
            sync_install = false,
            -- Automatically install missing parsers when entering buffer
            -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
            auto_install = true,
            ignore_install = {},
            modules = {},
            ensure_installed = {
                'query', -- needed for treesitter playground
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

        -- Skip backwards compatibility routines and speed up loading
        vim.g.skip_ts_context_commentstring_module = true
    end
}
