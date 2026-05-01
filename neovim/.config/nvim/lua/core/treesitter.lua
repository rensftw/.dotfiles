-- ────────────────────────────────────────────────────────────────────────────
-- Treesitter: native Neovim wiring
-- ────────────────────────────────────────────────────────────────────────────
-- Filetype-to-parser mappings + the FileType autocmd that calls
-- vim.treesitter.start(). Parser installation and the rest of the
-- treesitter plugin stack live in lua/plugins/treesitter-manager.lua.
--
-- Why here, not in the plugin spec:
--
--   tree-sitter-manager.nvim's `highlight = true` autocmd patterns on
--   parser *language* names — works when filetype == language (`lua`,
--   `python`), silently broken when they differ (`typescriptreact` →
--   `tsx`, `javascriptreact` → `tsx`). Open issues:
--     - https://github.com/romus204/tree-sitter-manager.nvim/issues/54
--     - https://github.com/romus204/tree-sitter-manager.nvim/issues/58
--   nvim-treesitter is archived, so we're staying with this plugin and
--   working around the bug ourselves. Doing it here (sourced from
--   init.lua, before lazy) means the autocmd is live before any FileType
--   fires; doing it in the plugin's `config` would miss the buffer that
--   triggered the lazy-load, since BufReadPost fires after FileType.
--
-- Implicit rtp dependency:
--
--   `vim.treesitter.start` finds parsers under `<rtp>/parser/` and
--   queries under `<rtp>/queries/`. tree-sitter-manager installs to
--   `stdpath('data')/site/{parser,queries}` by default, whose parent
--   (`~/.local/share/nvim/site`) is already on Neovim's default rtp — so
--   this works without the plugin loaded. If `parser_dir`/`query_dir`
--   are ever overridden to a non-`site/` path, the plugin's
--   `vim.opt.rtp:prepend` calls become load-bearing and this autocmd
--   will silently stop finding parsers. In that case, move this back
--   into the plugin's `config` with a catch-up loop over loaded buffers.
--
-- Debugging if highlighting stops working:
--
--   - `:lua print(vim.treesitter.highlighter.active[0] ~= nil)` — should
--     be `true` for any buffer whose filetype has an installed parser.
--   - `:lua print(vim.treesitter.language.get_lang(vim.bo.filetype))` —
--     should print the parser name; if it echoes the filetype back, add
--     a mapping to the `language.register` call below.
--   - `:checkhealth vim.treesitter` — installed parsers + missing queries.
--   - `:lua =vim.opt.rtp:get()` — should include `~/.local/share/nvim/site`.

-- Filetypes whose names don't match their parser. The `tsx` parser is a
-- superset that handles both TS+JSX and JS+JSX.
vim.treesitter.language.register('tsx', { 'typescriptreact', 'javascriptreact' })

vim.api.nvim_create_autocmd('FileType', {
    group = vim.api.nvim_create_augroup('treesitter_auto_start', {}),
    callback = function(ev) pcall(vim.treesitter.start, ev.buf) end,
    desc = 'Auto-enable treesitter for any installed parser',
})
