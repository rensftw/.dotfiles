return {
    'stevearc/conform.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    cmd = { 'ConformInfo' },
    keys = {
        {
            '<leader>af',
            function() require('conform').format({ async = true, lsp_format = 'fallback' }) end,
            mode = { 'n', 'v' },
            desc = '[A]uto [F]ormat',
        },
    },
    config = function()
        require('conform').setup({
            formatters_by_ft = {
                lua             = { 'stylua' },
                javascript      = { 'prettier' },
                javascriptreact = { 'prettier' },
                typescript      = { 'prettier' },
                typescriptreact = { 'prettier' },
                json            = { 'prettier' },
                jsonc           = { 'prettier' },
                yaml            = { 'prettier' },
                markdown        = { 'prettier' },
                html            = { 'prettier' },
                css             = { 'prettier' },
                scss            = { 'prettier' },
                -- Python formatting is handled by the ruff LSP.
                -- Shell scripts are left unformatted; add 'shfmt' here if desired.
            },
            -- Auto-formatting on save is intentionally disabled.
            -- Trigger manually with <leader>af.
        })
    end,
}
