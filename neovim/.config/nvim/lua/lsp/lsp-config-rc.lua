local M = {}

local highlight_symbol_under_cursor = function(client)
    if client.server_capabilities.document_highlight then
        vim.cmd [[
        hi LspReferenceRead cterm=bold ctermbg=red guibg=#414868
        hi LspReferenceText cterm=bold ctermbg=red guibg=#414868
        hi LspReferenceWrite cterm=bold ctermbg=red guibg=#414868
        augroup lsp_document_highlight
        autocmd! * <buffer>
        autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
        autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
        augroup END
        ]]
    end
end

local enable_format_on_save = function(client, bufnr)
    if client.supports_method('textDocument/formatting') and client.server_capabilities.document_formatting then
        local augroup = vim.api.nvim_create_augroup('LspFormatting', {})
        vim.api.nvim_clear_autocmds({ group = augroup, buffer = bufnr })
        vim.api.nvim_create_autocmd('BufWritePre', {
            group = augroup,
            buffer = bufnr,
            callback = function()
                vim.lsp.buf.format({ bufnr = bufnr })
            end,
        })
    end
end

M.on_attach = function(client, bufnr)
    -- formatting
    if client.name == 'tsserver' then
        client.server_capabilities.document_formatting = false
    end

    if client.name == 'eslint' then
        client.server_capabilities.document_formatting = false
    end

    if client.name == 'null-ls' then
        client.server_capabilities.document_formatting = false
    end

    enable_format_on_save(client, bufnr);
    highlight_symbol_under_cursor(client)
end

return M
