-- Globals
require 'user.options'
require 'user.packer'
require('user.theme')
require 'user.keymaps'
require 'user.autocommands'

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
