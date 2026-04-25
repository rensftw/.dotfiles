return {
    settings = {
        Lua = {
            runtime = {
                -- Neovim embeds LuaJIT, so tell lua_ls to use that runtime.
                version = 'LuaJIT',
            },
            workspace = {
                checkThirdParty = false,
                library = { vim.env.VIMRUNTIME },
            },
            diagnostics = {
                -- Silence "undefined global `vim`" in Neovim config files.
                globals = { 'vim' },
            },
            telemetry = { enable = false },
        },
    },
}
