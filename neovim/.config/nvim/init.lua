-- Globals
require 'user.options'
require 'user.packer'
require 'user.theme'
require 'user.keymaps'
require 'user.autocommands'

-- LSP setup
require 'lsp.setup-lsp-servers'

-- DAP setup
require 'dap.dap-rc'
require 'nvim-dap-virtual-text'.setup()

-- Plugin configuration
require 'plugin.nvim-web-devicons-rc'
require 'plugin.lualine-rc'
require 'plugin.nvim-treesitter-rc'
require 'plugin.telescope-rc'
require 'plugin.nvim-tree-rc'
require 'plugin.lspsaga-rc'
require 'plugin.nvim-cmp-rc'
require 'plugin.gitsigns-rc'
require 'plugin.luasnip-rc'
require 'plugin.doge-rc'
require 'plugin.autopairs-rc'
require 'plugin.alpha-rc'
require 'plugin.indent-blankline-rc'
require 'plugin.vim-tmux-navigator-rc'
require 'plugin.fidget-rc'

require 'Comment'.setup()
require 'colorizer'.setup()
require 'neoscroll'.setup()
