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

local enable_formatting_for_eligible_clients = function(client)
    if client.server_capabilities.document_formatting then
        vim.api.nvim_command [[augroup Format]]
        vim.api.nvim_command [[autocmd! * <buffer>]]
        vim.api.nvim_command [[autocmd BufWritePre <buffer> lua vim.lsp.buf.format()]]
        vim.api.nvim_command [[augroup END]]
    end
end

M.on_attach = function(client)
    -- formatting
    if client.name == 'tsserver' or client.name == 'volar' then
        client.server_capabilities.document_formatting = false
    end

    if client.name == 'eslint' then
        client.server_capabilities.document_formatting = false
    end

    enable_formatting_for_eligible_clients(client);
    highlight_symbol_under_cursor(client)
end

return M
