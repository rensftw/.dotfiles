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
        -- Show LSP status during startup
        'folke/noice.nvim',
        'j-hui/fidget.nvim',
        -- JSON schemas
        'b0o/schemastore.nvim',
    },
    config = function()
        require 'lsp.native-settings'
        require 'lsp.setup-lsp-servers'
    end
}
