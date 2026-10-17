-- Canonical list of LSP servers enabled by Neovim.
-- Mason installs every entry except servers supplied by their workspace.
return {
    -- JavaScript / TypeScript
    'tsc',      -- TypeScript 7 native LSP
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
    'marksman', -- Markdown
    'taplo',    -- TOML
    'yamlls',
}
