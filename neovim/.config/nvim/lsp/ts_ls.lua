return {
    commands = {
        -- Full list of TypeScript LSP commands:
        -- https://github.com/microsoft/TypeScript/tree/main/src/services
        OrganizeImports = {
            function()
                local params = {
                    command   = '_typescript.organizeImports',
                    arguments = { vim.api.nvim_buf_get_name(0) },
                }
                local clients = vim.lsp.get_clients({ name = 'ts_ls' })
                if clients[1] then
                    clients[1]:exec_cmd(params)
                end
            end,
            description = 'Organize Imports',
        },
    },
}
