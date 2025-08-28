-- Define diagnostic signs
vim.diagnostic.config({
    severity_sort = false,
    virtual_text = false,
    underline = true,
    update_in_insert = true,
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = '',
            [vim.diagnostic.severity.WARN] = '',
            [vim.diagnostic.severity.INFO] = '',
            [vim.diagnostic.severity.HINT] = '',
        },
        texthl = {
            [vim.diagnostic.severity.ERROR] = 'DiagnosticSignError',
            [vim.diagnostic.severity.WARN] = 'DiagnosticSignWarn',
            [vim.diagnostic.severity.INFO] = 'DiagnosticSignHint',
            [vim.diagnostic.severity.HINT] = 'DiagnosticSignInfo',
        },
    },
})

