local nvim_lsp = require('lspconfig')
local config = require('lsp.lspconfig-rc')

-- Set up completion using nvim_cmp with LSP source
local capabilities = require('cmp_nvim_lsp').update_capabilities(
  vim.lsp.protocol.make_client_capabilities()
)

local servers = {
    'bashls',
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
        on_attach = config.on_attach,
        capabilities = capabilities,
        flags = {
            debounce_text_changes = 150,
        }
    }
end

nvim_lsp.jsonls.setup {
    on_attach = config.on_attach,
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
    on_attach = config.on_attach,
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

nvim_lsp['sumneko_lua'].setup {
    on_attach = config.on_attach,
    capabilities = capabilities,
    flags = {
        debounce_text_changes = 150,
    },
    settings = {
        Lua = {
            diagnostics = {
                globals = {'vim'}
            }
        }
    }
}

nvim_lsp.efm.setup {
    on_attach = config.on_attach,
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
