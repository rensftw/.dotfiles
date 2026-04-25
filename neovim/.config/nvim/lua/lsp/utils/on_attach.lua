local M = {}

local highlight_symbol_under_cursor = function(client, bufnr)
    if not client:supports_method('textDocument/documentHighlight') then
        return
    end

    vim.api.nvim_set_hl(0, 'LspReferenceRead',  { bold = true, bg = '#414868' })
    vim.api.nvim_set_hl(0, 'LspReferenceText',  { bold = true, bg = '#414868' })
    vim.api.nvim_set_hl(0, 'LspReferenceWrite', { bold = true, bg = '#414868' })

    local group = vim.api.nvim_create_augroup('lsp_document_highlight_' .. bufnr, { clear = true })
    vim.api.nvim_create_autocmd('CursorHold', {
        group = group,
        buffer = bufnr,
        callback = vim.lsp.buf.document_highlight,
    })
    vim.api.nvim_create_autocmd('CursorMoved', {
        group = group,
        buffer = bufnr,
        callback = vim.lsp.buf.clear_references,
    })
end

-- Format-on-save and the <leader>af keymap are owned by conform.nvim.
-- See lua/plugins/conform.lua.

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
    keymap('n', '[d',         function() vim.diagnostic.jump({count=-1, float={source=true} }) end,'Previous diagnostic message')
    keymap('n', ']d',         function() vim.diagnostic.jump({count=1, float={source=true} }) end, 'Next diagnostic message')

    highlight_symbol_under_cursor(client, bufnr)
end

return M
