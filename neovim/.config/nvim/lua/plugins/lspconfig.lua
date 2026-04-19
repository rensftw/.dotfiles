return {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    keys = {
        { '<leader>li', '<cmd>LspInfo<CR>',    mode = 'n', desc = 'LSP info (checkhealth)' },
        { '<leader>ll', '<cmd>LspLog<CR>',     mode = 'n', desc = 'LSP log' },
        { '<leader>ls', '<cmd>LspStart<CR>',   mode = 'n', desc = 'LSP start (retrigger FileType)' },
        { '<leader>lq', '<cmd>LspStop<CR>',    mode = 'n', desc = 'LSP stop (current buffer)' },
        { '<leader>lr', '<cmd>LspRestart<CR>', mode = 'n', desc = 'LSP restart (current buffer)' },
    },
    dependencies = {
        -- Manage LSP dependencies
        'williamboman/mason.nvim',
        'williamboman/mason-lspconfig.nvim',
        'folke/lazydev.nvim',
        'nvimtools/none-ls.nvim',
        -- JSON schemas
        'b0o/schemastore.nvim',
    },
    config = function()
        -- IMPORTANT: lazydev must load before LSP setup
        require('lazydev').setup()
        require('lsp.utils.setup-lsp-servers')
    end,
}
