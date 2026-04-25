return {
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    dependencies = { 'mason-org/mason.nvim' },
    event = 'VeryLazy',
    config = function()
        require('mason-tool-installer').setup({
            -- Non-LSP tools (formatters, linters). LSP servers stay in
            -- mason-lspconfig's ensure_installed list.
            ensure_installed = {
                'prettier',   -- formatter (js/ts/json/yaml/md/html/css)
                'stylua',     -- formatter (lua)
                'shellcheck', -- linter (sh/bash)
                'actionlint', -- linter (github workflows)
                'vale',       -- linter (prose) — wired but currently disabled in nvim-lint
            },
            run_on_start = true,
        })
    end,
}
