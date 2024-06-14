return {
    'neovim/nvim-lspconfig',
    keys = {
        { mode = { 'n' }, '<leader>li',   ':LspInfo<CR>', },
        { mode = { 'n' }, '<leader>ll',   ':LspLog<CR>', },
        { mode = { 'n' }, '<leader>ls',   ':LspStart<CR>', },
        { mode = { 'n' }, '<leader>lq',   ':LspStop<CR>', },
        { mode = { 'n' }, '<leader>lr',   ':LspRestart<CR>', },
    },
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
        -- Manage LSP dependencies
        'williamboman/mason.nvim',
        'williamboman/mason-lspconfig.nvim',
        'folke/lazydev.nvim',
        'nvimtools/none-ls.nvim',
        'nvimdev/lspsaga.nvim',
        -- JSON schemas
        'b0o/schemastore.nvim',
    },
    config = function()
        -- IMPORTANT: make sure to setup neodev BEFORE nvim_lsp/lspconfig
        require('lazydev').setup()
        require('lsp.utils.setup-lsp-servers')
    end
}
