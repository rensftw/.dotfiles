return {
    'williamboman/mason-lspconfig.nvim',
    lazy = true,
    config = function()
        require('mason-lspconfig').setup({
            ensure_installed = {
                -- JavaScript/Typescript language support
                'ts_ls',    -- LSP
                'eslint',   -- Linting
                -- Python language support
                'pyright',  -- LSP
                'ruff',     -- Linting, formatting, import organization
                -- Random other language servers
                'bashls',
                'jsonls',
                'html',
                'yamlls',
                'lua_ls',
                'dockerls',
            },
        })
    end
}
