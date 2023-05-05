-- Globals
require 'user.options'
require 'user.keymaps'
require 'user.autocommands'
require 'user.commands'
require 'user.packer'
require 'user.theme'

-- Mason: LSP and DAP depedency manager
require 'plugin.mason-rc'

-- LSP setup
require 'lsp.native-settings'
require 'lsp.setup-lsp-servers'
require 'lsp.lsp-signature-rc'
require 'lsp.lspsaga-rc'

-- DAP setup
require 'dap.dap-rc'
require 'nvim-dap-virtual-text'.setup()

-- Treesitter
require 'plugin.nvim-treesitter-rc'
require 'treesitter-context'.setup()

-- Plugin configuration
require('plugin.chatgpt-rc')
require 'plugin.nvim-web-devicons-rc'
require 'plugin.feline-rc'
require 'plugin.telescope-rc'
require 'plugin.nvim-tree-rc'
require 'plugin.nvim-cmp-rc'
require 'plugin.gitsigns-rc'
require 'plugin.luasnip-rc'
require 'plugin.doge-rc'
require 'plugin.autopairs-rc'
require 'plugin.alpha-rc'
require 'plugin.indent-blankline-rc'
require 'plugin.vim-tmux-navigator-rc'
require 'plugin.fidget-rc'
require 'plugin.undotree-rc'
require 'plugin.nnn-rc'

require 'Comment'.setup()
require 'colorizer'.setup()
