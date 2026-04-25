-- Canonical list of LSP servers used across the config.
-- Consumed by plugins/mason-lspconfig.lua (ensure_installed) and
-- lsp/utils/setup-lsp-servers.lua (vim.lsp.config + enable loop).
return {
    -- JavaScript / TypeScript
    'ts_ls',    -- LSP
    'eslint',   -- linting
    -- Python
    'pyright',  -- LSP
    'ruff',     -- linting, formatting, import organization
    -- Miscellaneous
    'bashls',
    'dockerls',
    'html',
    'jsonls',
    'lua_ls',
    'taplo',    -- TOML
    'yamlls',
}
