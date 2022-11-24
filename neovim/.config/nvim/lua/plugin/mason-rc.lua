require('mason').setup({
    ui = {
        border = { '╭', '─', '╮', '│', '╯', '─', '╰', '│' },
        icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗"
        }
    }
})

require('mason-lspconfig').setup({
    ensure_installed = {
        'tsserver',
        'jsonls',
        'eslint',
        'html',
        'emmet_ls',
        'cssls',
        'yamlls',
        'sumneko_lua',
        'dockerls',
        'rust_analyzer',
    },
})

require('mason-nvim-dap').setup({
    ensure_installed = {
        'js'
    }
});

