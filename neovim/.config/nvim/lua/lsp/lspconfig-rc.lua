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

local highlight_symbol_under_cursor = function(client)
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

local enable_formatting_for_eligible_clients = function(client)
    if client.resolved_capabilities.document_formatting then
        vim.api.nvim_command [[augroup Format]]
        vim.api.nvim_command [[autocmd! * <buffer>]]
        vim.api.nvim_command [[autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_seq_sync()]]
        vim.api.nvim_command [[augroup END]]
    end
end

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
M.on_attach = function(client, bufnr)
    local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end

    -- Mappings
    local opts = { noremap = true, silent = true }

    buf_set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
    buf_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
    buf_set_keymap('n', 'gt', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
    buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
    buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
    buf_set_keymap('n', 'H', '<cmd>Lspsaga hover_doc<CR>', opts)
    buf_set_keymap('n', '<leader>r', '<cmd>Lspsaga rename<CR>', opts)
    buf_set_keymap('n', '<leader>ca', '<cmd>Lspsaga code_action<CR>', opts)
    buf_set_keymap('n', '<leader>d', '<cmd>lua Virtual_text.toggle()<CR>', opts)
    buf_set_keymap('n', '[d', '<cmd>Lspsaga diagnostic_jump_prev<CR>', opts)
    buf_set_keymap('n', ']d', '<cmd>Lspsaga diagnostic_jump_next<CR>', opts)
    buf_set_keymap('n', '<leader>af', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)
    -- buf_set_keymap('i', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
    -- buf_set_keymap('n', '<leader>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
    -- buf_set_keymap('n', '<leader>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
    -- buf_set_keymap('n', '<leader>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
    -- buf_set_keymap('n', '<leader>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
    buf_set_keymap('n', '<S-up>', "<cmd>lua require('lspsaga.action').smart_scroll_with_saga(-1)<CR>", opts)
    buf_set_keymap('n', '<S-down>', "<cmd>lua require('lspsaga.action').smart_scroll_with_saga(1)<CR>", opts)

    -- formatting
    if client.name == 'tsserver' or client.name == 'volar' then
        client.resolved_capabilities.document_formatting = false
    end

    if client.name == 'eslint' then
        client.resolved_capabilities.document_formatting = true
    end

    enable_formatting_for_eligible_clients(client);
    highlight_symbol_under_cursor(client)
end

return M
