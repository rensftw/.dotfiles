return {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
        -- Manage LSP dependencies
        'williamboman/mason.nvim',
        'williamboman/mason-lspconfig.nvim',
        'folke/neodev.nvim',
        'jose-elias-alvarez/null-ls.nvim',
        'nvimdev/lspsaga.nvim',
        -- JSON schemas
        'b0o/schemastore.nvim',
    },
    config = function()
        -- IMPORTANT: make sure to setup neodev BEFORE nvim_lsp/lspconfig
        require('neodev').setup()
        require('lsp.utils.setup-lsp-servers')
    end
}
