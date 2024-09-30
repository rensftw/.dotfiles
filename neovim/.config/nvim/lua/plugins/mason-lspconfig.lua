return {
    'williamboman/mason-lspconfig.nvim',
    lazy = true,
    config = function()
        require('mason-lspconfig').setup({
            ensure_installed = {
                'bashls',
                'ts_ls',
                'jsonls',
                'eslint',
                'html',
                'emmet_ls',
                'cssls',
                'yamlls',
                'lua_ls',
                'dockerls',
                'rust_analyzer',
            },
        })
    end
}
