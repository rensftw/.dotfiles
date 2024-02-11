-- Extend sensible configs to improve writing experience
local markdown_config_path = vim.fn.stdpath('config') .. '/after/ftplugin/markdown.lua'
dofile(markdown_config_path)

vim.opt_local.spelllang = 'en'
vim.opt_local.colorcolumn = '+0'

-- Fun fact:
-- `Gitcommit` filetypes default to 72 lines of textwidth (and not 80 which is the default)
