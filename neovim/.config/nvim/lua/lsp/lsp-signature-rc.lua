require 'lsp_signature'.setup({
    bind = true, -- This is mandatory, otherwise border config won't get registered.
    handler_opts = { border = 'rounded' },
    hint_enable = false,
    max_width = 80,
    toggle_key = '<C-h>'
})
