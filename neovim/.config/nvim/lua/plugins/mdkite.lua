return {
    'selimacerbas/mdkite.nvim',
    enabled = true,
    dependencies = {
        -- mdkite's own lazy.lua also lists kitehost as a top-level spec, which
        -- makes lazy.nvim load it at startup; pin it lazy so it loads with mdkite.
        { 'selimacerbas/kitehost.nvim', lazy = true },
    },
    cmd = { 'MdKite' },
    ft = { 'markdown' },
    config = function()
        require('mdkite').setup({
            instance_mode = 'takeover', -- 'takeover' (one tab) or 'multi' (tab per instance)
            port = 0,                   -- 0 = auto (8421 for takeover, OS-assigned for multi)
            open_browser = true,
            default_theme = 'dark',
            mermaid_renderer = 'rust'
        })
    end,
    keys = {
        { '<leader>mp', '<cmd>MdKite start<cr>', ft = 'markdown', desc = 'Markdown preview (browser)' },
        { '<leader>mP', '<cmd>MdKite stop<cr>',  ft = 'markdown', desc = 'Markdown preview stop' },
    }
}
