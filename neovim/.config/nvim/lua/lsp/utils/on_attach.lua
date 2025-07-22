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
    if client:supports_method('textDocument/formatting') and client.server_capabilities.document_formatting then
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

local block_typescript_formatting = function(client)
    -- Never request typescript-language-server for formatting
    local clientsWithDisabledFormatting = { 'ts_ls', 'eslint' }
    for _, name in ipairs(clientsWithDisabledFormatting) do
        if client.name == name then
            return false
        end
    end
    return true
end

M.on_attach = function(client, bufnr)
    local telescope = require('telescope.builtin')
    local keymap = function(mode, keys, func, desc)
        if desc then
          desc = 'LSP: ' .. desc
        end

        local opts = { buffer = bufnr, desc = desc, noremap = true, silent = true }
        vim.keymap.set(mode, keys, func, opts)
      end

    -- LSP keymaps
    keymap('n', 'gD',         vim.lsp.buf.declaration,                                             '[Go]to [D]eclaration')
    keymap('n', 'gd',         vim.lsp.buf.definition,                                              '[G]oto [D]efinition')
    keymap('n', 'gt',         vim.lsp.buf.type_definition,                                         '[G]oto [T]ype definition')
    keymap('n', 'gi',         vim.lsp.buf.implementation,                                          '[G]oto [I]mplementation')
    keymap('n', 'gr',         function() telescope.lsp_references({initial_mode = 'normal'}) end,  '[G]oto [R]eferences')
    keymap('n', 'H',          vim.lsp.buf.hover,                                                   '[H]over')
    keymap('n', '<leader>r',  vim.lsp.buf.rename,                                                  '[R]ename')
    keymap({'n', 'v'}, '<leader>ca',  vim.lsp.buf.code_action,                                     '[C]ode [A]ction')
    keymap('n', '<leader>D',  require('core.helpers').Virtual_text.toggle,                         '[D]iagnostics')
    keymap('n', '[d',         function() vim.diagnostic.jump({count=1, float=true}) end,                          'Previous diagnostic message')
    keymap('n', ']d',         function() vim.diagnostic.jump({count=-1, float=true}) end,                         'Next diagnostic message')
    keymap({'n', 'v'}, '<leader>af', function()
            vim.lsp.buf.format({
                async = true,
                filter = block_typescript_formatting
            })
        end,
        '[A]uto [F]ormat')

    enable_format_on_save(client, bufnr);
    highlight_symbol_under_cursor(client);
end

return M
