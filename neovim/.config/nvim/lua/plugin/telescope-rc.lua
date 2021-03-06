require('telescope').setup {
    defaults = {
        mappings = {
            n = {
                ['dd'] = require('telescope.actions').delete_buffer
            },
            i = {
                ['<c-d>'] = require('telescope.actions').delete_buffer
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
        prompt_prefix = '  ',
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
            find_command = { "fd", "--type", "f", "--strip-cwd-prefix" }
        }
    }
}

require('telescope').load_extension('fzf')
