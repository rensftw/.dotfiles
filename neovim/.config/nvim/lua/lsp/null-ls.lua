return {
    'nvimtools/none-ls.nvim',
    lazy = true,
    config = function()
        local config = require('lsp.utils.on_attach')
        local null_ls = require('null-ls')
        null_ls.setup({
            on_attach = config.on_attach,
            sources = {
                -- null_ls.builtins.diagnostics.vale,
                null_ls.builtins.formatting.prettier,
                null_ls.builtins.diagnostics.actionlint,
            },
        })
    end
}
