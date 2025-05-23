local nvim_lsp = require('lspconfig')
local config = require('lsp.utils.on_attach')
require('lspconfig.ui.windows').default_options.border = 'rounded'

-- Set up completion using nvim_cmp with LSP source
local capabilities = require('cmp_nvim_lsp').default_capabilities(
    vim.lsp.protocol.make_client_capabilities()
)

-- Set rounded borders for floating preview windows
local orig_util_open_floating_preview = vim.lsp.util.open_floating_preview
function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
  opts = opts or {}
  opts.border = opts.border or 'rounded'
  return orig_util_open_floating_preview(contents, syntax, opts, ...)
end

local servers = {
    -- JavaScript/Typescript language support
    'ts_ls',    -- LSP
    'eslint',   -- Linting
    -- Python language support
    'pyright',  -- LSP
    'ruff',     -- Linting, formatting, import organization
    -- Random other language servers
    'bashls',
    'jsonls',
    'html',
    'yamlls',
    'lua_ls',
    'dockerls',
}

local server_config = {
    ts_ls = {
        commands = {
            -- Full list of TypeScript LSP commands
            -- https://github.com/microsoft/TypeScript/tree/main/src/services
            OrganizeImports = {
                function ()
                    local params = {
                        command = "_typescript.organizeImports",
                        arguments = {vim.api.nvim_buf_get_name(0)},
                    }
                    vim.lsp.buf.execute_command(params)
                end,
                description = "Organize Imports"
            }
        }
    },
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
                schemaStore = {
                    enable = true,
                    -- Avoid TypeError: Cannot read properties of undefined (reading 'length')
                    url = "",
                },
                schemas = require('schemastore').yaml.schemas(),
            }
        }
    },
    lua_ls = {
        settings = {
            Lua = {
                runtime = {
                    -- Tell the language server which version of Lua you're using
                    -- (most likely LuaJIT in the case of Neovim)
                    version = 'LuaJIT'
                },
                workspace = {
                    checkThirdParty = false,
                    library = {
                        vim.env.VIMRUNTIME
                    }
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
    local init_options = server_config[lsp] and server_config[lsp].init_options or {}
    local settings = server_config[lsp] and server_config[lsp].settings or {}
    local commands = server_config[lsp] and server_config[lsp].commands or {}

    nvim_lsp[lsp].setup {
        on_attach = config.on_attach,
        capabilities = capabilities,
        flags = {
            debounce_text_changes = 150,
        },
        settings = settings,
        commands = commands,
        init_options = init_options,
    }
end
