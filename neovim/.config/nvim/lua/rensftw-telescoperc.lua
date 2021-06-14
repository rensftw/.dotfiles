local actions = require('telescope.actions')

require('telescope').setup{
  defaults = {
    vimgrep_arguments = {
        'rg',
        '--hidden',
        '--color=never',
        '--no-heading',
        '--with-filename',
        '--line-number',
        '--column',
        '--smart-case',
    },
    file_ignore_patterns = {
        '.git',
        'node_modules'
    },
    prompt_prefix = "❯ ",
    selection_caret = "❯ ",
    prompt_position = "top",
    selection_strategy = "reset",
    sorting_strategy = "ascending",
    scroll_strategy = "cycle",
    color_devicons = true,
    winblend = 0,
    layout_strategy = "horizontal",
    layout_config = {
      width = 0.8,
      height = 0.85,
      preview_cutoff = 120,

      horizontal = {
        -- width_padding = 0.1,
        -- height_padding = 0.1,
        preview_width = 0.6,
      },

      vertical = {
        -- width_padding = 0.05,
        -- height_padding = 1,
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
    mappings = {
      i = {
        ["<esc>"] = actions.close
      },
    },
  }
}

require('telescope').load_extension('fzf')

