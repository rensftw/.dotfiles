-- Cache Lua module loading as early as possible.
if vim.loader then
    vim.loader.enable()
end

-- Native configs
require 'core.options'
require 'core.autocommands'
require 'core.commands'
require 'core.keymaps'
require 'core.native-lsp-settings'
require 'core.treesitter'

-- Packages
require 'core.lazy'
