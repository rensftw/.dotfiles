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
    local telescope = require('telescope.builtin')
    local nmap = function(keys, func, desc)
        if desc then
          desc = 'LSP: ' .. desc
        end

        local opts = { buffer = bufnr, desc = desc, noremap = true, silent = true }
        vim.keymap.set('n', keys, func, opts)
      end

    -- LSP keymaps
    nmap('gD', vim.lsp.buf.declaration, '[Go]to [D]eclaration')
    nmap('gd', vim.lsp.buf.definition, '[G]oto [D]efinition')
    nmap('gt', vim.lsp.buf.type_definition, '[G]oto [T]ype definition')
    nmap('gi', vim.lsp.buf.implementation, '[G]oto [I]mplementation')
    nmap('gr', function() telescope.lsp_references({initial_mode = 'normal'}) end, '[G]oto [R]eferences')
    nmap('H', '<cmd>Lspsaga hover_doc<CR>', '[H]over')
    nmap('<leader>r', '<cmd>Lspsaga rename<CR>', '[R]ename')
    nmap('<leader>ca', '<cmd>Lspsaga code_action<CR>', '[C]ode [A]ction')
    nmap('<leader>d', require("user.helpers").Virtual_text.toggle, '[D]iagnostics')
    nmap('[d', '<cmd>Lspsaga diagnostic_jump_prev<CR>', 'Previous diagnostic message')
    nmap(']d', '<cmd>Lspsaga diagnostic_jump_next<CR>', 'Next diagnostic message')
    nmap('<leader>af', function() vim.lsp.buf.format({ async = true }) end, '[A]uto [F]ormat')
    nmap('<S-up>', function() require('lspsaga.action').smart_scroll_with_saga(-1) end, 'Scroll up in code action')
    nmap('<S-down>', function() require('lspsaga.action').smart_scroll_with_saga(1) end,  'Scroll down in code action')

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
