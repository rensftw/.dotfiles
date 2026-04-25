--[[
LSP setup

Layout
------
  lua/lsp/utils/server-list.lua         — list of servers to install and enable
  lua/lsp/utils/on_attach.lua           — callback with per-buffer keymaps,
                                          invoked via the LspAttach autocmd below
  lua/lsp/utils/setup-lsp-servers.lua   — this file: shared defaults + enable loop
  ~/.config/nvim/lsp/<server>.lua       — per-server overrides / extensions
                                          (optional; see below)

Per-server config
-----------------
Neovim 0.11's `vim.lsp.enable(name)` automatically discovers and merges every
`lsp/<name>.lua` file it finds on `runtimepath`, including:

  1. `nvim-lspconfig`'s shipped defaults (cmd, filetypes, root_markers, …)
  2. Your override at `~/.config/nvim/lsp/<name>.lua` (if present)
  3. Your `vim.lsp.config('*', { … })` defaults below (capabilities)

A per-server file is ONLY needed when you want to change or extend the
shipped defaults. Servers that work as-is (e.g. `ruff`, `pyright`,
`bashls`, `dockerls`, `html`, `taplo`, `eslint`) don't need a file —
just add them to server-list.lua and they pick up the defaults.
]]

-- Capabilities must be set *before* the server starts so the LSP handshake
-- negotiates the correct feature set. That means they go through
-- vim.lsp.config('*', …), not through an LspAttach autocmd.
local capabilities = require('blink.cmp').get_lsp_capabilities()

vim.lsp.config('*', {
    capabilities = capabilities,
})

-- Per-buffer keymaps and document-highlight wiring fire on every attach.
-- Using LspAttach here keeps the keymap logic in one place instead of
-- threading `on_attach` through every server config.
vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('lsp_attach', { clear = true }),
    callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client then
            require('lsp.utils.on_attach').on_attach(client, args.buf)
        end
    end,
})

-- Enable every server in the canonical list. Each call triggers discovery
-- of any `~/.config/nvim/lsp/<name>.lua` override and merges it with
-- nvim-lspconfig's shipped defaults.
for _, name in ipairs(require('lsp.utils.server-list')) do
    vim.lsp.enable(name)
end
