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
    'jsonls',
    'yamlls',
    'emmet_ls',
    'eslint',
    'vuels',
    'tsserver',
    'sumneko_lua',
    'efm',
}

local server_settings = {
    jsonls = {
        json = {
            schemas = require('schemastore').json.schemas(),
        },
    },
    yamlls = {
        yaml = {
            schemaStore = {enable = true}
        }
    },
    sumneko_lua = {
        Lua = {
            diagnostics = {
                globals = {'vim'}
            }
        }
    },
    efm = {
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
    },
}

for _, lsp in ipairs(servers) do
    nvim_lsp[lsp].setup {
        on_attach = config.on_attach,
        capabilities = capabilities,
        flags = {
            debounce_text_changes = 150,
        },
        settings = server_settings[lsp] or {}
    }
end
