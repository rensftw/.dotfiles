local M = {}

-- Toggle iniline diagnostics
Virtual_text = {}
Virtual_text.show = true
Virtual_text.toggle = function()
    Virtual_text.show = not Virtual_text.show
    vim.diagnostic.config({
        virtual_text = Virtual_text.show,
        update_in_insert = true,
        severity_sort = true,
    })
end

M.highlight_symbol_under_cursor = function (client)
    if client.resolved_capabilities.document_highlight then
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

M.enable_formatting_for_eligible_clients = function (client)
    if client.resolved_capabilities.document_formatting then
        vim.api.nvim_command [[augroup Format]]
        vim.api.nvim_command [[autocmd! * <buffer>]]
        vim.api.nvim_command [[autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_seq_sync()]]
        vim.api.nvim_command [[augroup END]]
    end
end

return M
