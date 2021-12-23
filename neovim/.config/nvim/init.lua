-- Globals
require 'user.options'
require 'user.plugins'
require 'user.keymaps'
require 'user.autocommands'

-- Theme
vim.g.tokyonight_style = 'night'
vim.g.tokyonight_lualine_bold = 'true'
vim.cmd [[colorscheme tokyonight]]

-- LSP setup
require 'lsp.setup-lsp-servers'

-- Plugin configuration
require 'plugin.lualine-rc'
require 'plugin.nvim-treesitter-rc'
require 'plugin.telescope-rc'
require 'plugin.trouble-rc'
require 'plugin.nvim-tree-rc'
require 'plugin.lspsaga-rc'
require 'plugin.nvim-cmp-rc'
require 'plugin.gitsigns-rc'
require 'plugin.ultisnips-rc'
require 'plugin.doge-rc'
require 'plugin.autopairs-rc'
require 'plugin.alpha-rc'

require 'Comment'.setup()
require 'colorizer'.setup()
require 'toggleterm'.setup()

