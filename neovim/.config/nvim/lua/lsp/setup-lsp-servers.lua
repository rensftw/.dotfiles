local nvim_lsp = require('lspconfig')
local config = require('lsp.lspconfig-rc')

-- Set up completion using nvim_cmp with LSP source
local capabilities = require('cmp_nvim_lsp').update_capabilities(
    vim.lsp.protocol.make_client_capabilities()
)

-- Retrieve the global TS server library for the currently active node version
local function get_global_typescript_server()
    local command = 'which node'
    local handle = io.popen(command)
    local result = handle:read()
    handle:close()

    local globalNodePath = string.gsub(result, 'bin/node', '')
    return globalNodePath .. 'lib/node_modules/typescript/lib/tsserverlibrary.js'
end

local servers = {
    'tsserver',
    'jsonls',
    'volar',
    'eslint',
    'html',
    'emmet_ls',
    'cssls',
    'yamlls',
    'bashls',
    'vimls',
    'sumneko_lua',
    'dockerls',
    'efm',
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
    volar = {
        init_options = {
            typescript = {
                serverPath = get_global_typescript_server()
            }
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
    efm = {
        init_options = {
            documentFormatting = false
        },
        settings = {
            rootMarkers = { ".git/" },
            languages = {
                markdown = {
                    {
                        lintCommand = 'vale --output=$HOME/.config/vale/output.tmpl ${INPUT}',
                        lintStdin = false,
                        lintFormats = {
                            '%f:%l:%c:%trror:%m',
                            '%f:%l:%c:%tarning:%m',
                            '%f:%l:%c:%tnfo:%m',
                        }
                    },
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
