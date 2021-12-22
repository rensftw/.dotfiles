local nvim_lsp = require('lspconfig')

-- Toggle inline LSP warnings/errors
local virtual_text = {}
virtual_text.show = true
virtual_text.toggle = function()
    virtual_text.show = not virtual_text.show
    if virtual_text.show == true then
        print('Show diagnostics')
        vim.lsp.diagnostic.enable()
    else
        print('Hide diagnostics')
        vim.lsp.diagnostic.disable()
    end
end

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end

  -- Mappings
  local opts = { noremap=true, silent=true }

  buf_set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  buf_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', 'H', '<cmd>Lspsaga hover_doc<CR>', opts)
  buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
  buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  --buf_set_keymap('i', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
  buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
  buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
  buf_set_keymap('n', '<space>rn', '<cmd>Lspsaga rename<CR>', opts)
  buf_set_keymap('n', '<space>ca', '<cmd>Lspsaga range_code_action<CR>', opts)
  buf_set_keymap('n', '<space>D', '<cmd>lua virtual_text.toggle()<CR>', opts)
  buf_set_keymap('n', '[d', '<cmd>Lspsaga diagnostic_jump_prev<CR>', opts)
  buf_set_keymap('n', ']d', '<cmd>Lspsaga diagnostic_jump_next<CR>', opts)
  buf_set_keymap('n', '<space>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
  buf_set_keymap('n', '<space>af', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)
  buf_set_keymap('n', '<S-up>', "<cmd>lua require('lspsaga.action').smart_scroll_with_saga(-1)<CR>", opts)
  buf_set_keymap('n', '<S-down>', "<cmd>lua require('lspsaga.action').smart_scroll_with_saga(1)<CR>", opts)

  -- formatting
  if client.name == 'tsserver' then
    client.resolved_capabilities.document_formatting = false
  end

  if client.name == 'eslint' then
    client.resolved_capabilities.document_formatting = true
  end

  if client.resolved_capabilities.document_formatting then
    vim.api.nvim_command [[augroup Format]]
    vim.api.nvim_command [[autocmd! * <buffer>]]
    vim.api.nvim_command [[autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_seq_sync()]]
    vim.api.nvim_command [[augroup END]]
  end
end

-- Set up completion using nvim_cmp with LSP source
local capabilities = require('cmp_nvim_lsp').update_capabilities(
  vim.lsp.protocol.make_client_capabilities()
)

local servers = {
    'bashls',
    'sumneko_lua',
    'vimls',
    'html',
    'cssls',
    'emmet_ls',
    'eslint',
    'vuels',
    'tsserver',
}
for _, lsp in ipairs(servers) do
    nvim_lsp[lsp].setup {
        on_attach = on_attach,
        capabilities = capabilities,
        flags = {
            debounce_text_changes = 150,
        }
    }
end

nvim_lsp.jsonls.setup {
    on_attach = on_attach,
    capabilities = capabilities,
    flags = {
        debounce_text_changes = 150,
    },
    settings = {
        json = {
            schemas = require('schemastore').json.schemas(),
        },
    },
}

nvim_lsp.yamlls.setup {
    on_attach = on_attach,
    capabilities = capabilities,
    flags = {
        debounce_text_changes = 150,
    },
    settings = {
        yarml = {
            schemaStore = {enable = true}
        }
    }
}

nvim_lsp.efm.setup {
    on_attach = on_attach,
    capabilities = capabilities,
    flags = {
        debounce_text_changes = 150,
    },
    settings = {
        rootMarkers = {".git/"},
        languages = {
            markdown = {
                {
                    lintCommand = 'vale --output=$HOME/.config/vale/output.tmpl ${INPUT}',
                    lintStdin= false,
                    lintFormats = {
                        '%f:%l:%c:%trror %m',
                        '%f:%l:%c:%tarning %m',
                        '%f:%l:%c:%tuggestion %m',
                    }
                },
            }
        }
    }
}
