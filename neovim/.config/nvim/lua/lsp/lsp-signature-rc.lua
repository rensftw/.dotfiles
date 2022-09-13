require 'lsp_signature'.setup({
    bind = false, -- Set to false so that it works with LSP saga
    handler_opts = { border = 'rounded' },
    hint_enable = false,
    max_width = 80,
    toggle_key = '<C-h>'
})
