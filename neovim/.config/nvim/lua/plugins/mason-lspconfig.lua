return {
    'mason-org/mason-lspconfig.nvim',
    lazy = true,
    config = function()
        -- Native TypeScript servers use the workspace or PATH binary, not Mason.
        local workspace_servers = { tsc = true }
        local mason_servers = vim.tbl_filter(function(server)
            return not workspace_servers[server]
        end, require('lsp.utils.server-list'))

        require('mason-lspconfig').setup({
            ensure_installed = mason_servers,
            automatic_enable = false,
        })
    end
}
