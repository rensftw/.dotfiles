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

local block_typescript_formatting = function(client)
    -- Never request typescript-language-server for formatting
    local clientsWithDisabledFormatting = { 'tsserver', 'eslint' }
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
    keymap('n', 'H',          '<cmd>Lspsaga hover_doc<CR>',                                        '[H]over')
    keymap('n', '<leader>r',  '<cmd>Lspsaga rename<CR>',                                           '[R]ename')
    keymap('n', '<leader>ca', '<cmd>Lspsaga code_action<CR>',                                      '[C]ode [A]ction')
    keymap('n', '<leader>d',  require('core.helpers').Virtual_text.toggle,                         '[D]iagnostics')
    keymap('n', '[d',         '<cmd>Lspsaga diagnostic_jump_prev<CR>',                             'Previous diagnostic message')
    keymap('n', ']d',         '<cmd>Lspsaga diagnostic_jump_next<CR>',                             'Next diagnostic message')
    keymap('n', '<S-up>',     function() require('lspsaga.action').smart_scroll_with_saga(-1) end, 'Scroll up in code action')
    keymap('n', '<S-down>',   function() require('lspsaga.action').smart_scroll_with_saga(1) end,  'Scroll down in code action')
    keymap('n', '<leader>af', function()
            vim.lsp.buf.format({
                async = true,
                filter = block_typescript_formatting
            })
        end,
        '[A]uto [F]ormat')

    keymap('v', '<leader>af', function()
            -- NOTE: `table.unpack` is available in Lua 5.2+
            -- Neovim uses LuaJIT with v5.1 so we need to use the global `unpack` method
            -- which will be deprecated in Lua 5.3+
            local unpack = table.unpack or unpack
            local start_row, _ = unpack(vim.api.nvim_buf_get_mark(0, '<'))
            local end_row, _ = unpack(vim.api.nvim_buf_get_mark(0, '>'))

            vim.lsp.buf.format({
                async = true,
                range = {
                    ['start'] = { start_row, 0 },
                    ['end'] = { end_row, 0 },
                },
                filter = block_typescript_formatting
            })
        end,
        '[A]uto [F]ormat visual selection')

    enable_format_on_save(client, bufnr);
    highlight_symbol_under_cursor(client)
end

return M
