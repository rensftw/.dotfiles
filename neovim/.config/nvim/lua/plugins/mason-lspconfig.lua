return {
    'mason-org/mason-lspconfig.nvim',
    lazy = true,
    config = function()
        require('mason-lspconfig').setup({
            ensure_installed = require('lsp.utils.server-list'),
        })
    end
}
