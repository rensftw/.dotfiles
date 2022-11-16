local nvim_lsp = require('lspconfig')
local config = require('lsp.lspconfig-rc')

-- Set up completion using nvim_cmp with LSP source
local capabilities = require('cmp_nvim_lsp').default_capabilities(
    vim.lsp.protocol.make_client_capabilities()
)

local servers = {
    'tsserver',
    'jsonls',
    'eslint',
    'html',
    'emmet_ls',
    'cssls',
    'yamlls',
    'sumneko_lua',
    'dockerls',
    'rust_analyzer'
}

local server_config = {
    jsonls = {
        settings = {
            json = {
                schemas = require('schemastore').json.schemas(),
                validate = { enable = true },
            },
        }
    },
    yamlls = {
        settings = {
            yaml = {
                schemaStore = { enable = true }
            }
        }
    },
    sumneko_lua = {
        settings = {
            Lua = {
                runtime = {
                    -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
                    version = 'LuaJIT'
                },
                diagnostics = {
                    globals = { 'vim' }
                },
                telemetry = {
                    enable = false
                }
            }
        }
    },
}

for _, lsp in ipairs(servers) do
    local settings = server_config[lsp] and server_config[lsp].settings or {}
    local init_options = server_config[lsp] and server_config[lsp].init_options or {}

    nvim_lsp[lsp].setup {
        on_attach = config.on_attach,
        capabilities = capabilities,
        flags = {
            debounce_text_changes = 150,
        },
        settings = settings,
        init_options = init_options,
    }
end

require('null-ls').setup({
    sources = {
        require('null-ls').builtins.diagnostics.vale,
    },
})
