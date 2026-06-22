-- Native Treesitter wiring. Parser installation and the rest of the Treesitter
-- plugin stack live in lua/plugins/treesitter-manager.lua.
--
-- This stays in init.lua (before lazy) so the FileType autocmd is registered
-- before the first buffer's FileType event. tree-sitter-manager's own
-- highlighting autocmd is parser-name based, which misses filetypes whose names
-- differ from their parser (for example typescriptreact/javascriptreact -> tsx).

-- Filetypes whose names don't match their parser. The `tsx` parser is a
-- superset that handles both TS+JSX and JS+JSX.
vim.treesitter.language.register('tsx', { 'typescriptreact', 'javascriptreact' })

vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('treesitter_auto_start', {}),
    callback = function(ev) pcall(vim.treesitter.start, ev.buf) end,
    desc = 'Auto-enable treesitter for any installed parser',
})
