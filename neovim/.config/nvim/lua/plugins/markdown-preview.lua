return {
    'selimacerbas/markdown-preview.nvim',
    enabled = true,
    dependencies = {
        'selimacerbas/live-server.nvim',
    },
    cmd = {
        'MarkdownPreview',
        'MarkdownPreviewRefresh',
        'MarkdownPreviewStop',
    },
    ft = { 'markdown' },
    config = function()
        require('markdown_preview').setup({
            instance_mode = 'takeover', -- 'takeover' (one tab) or 'multi' (tab per instance)
            port = 0,                   -- 0 = auto (8421 for takeover, OS-assigned for multi)
            open_browser = true,
            default_theme = 'dark',
            mermaid_renderer = 'rust,'
        })
    end,
    keys = {
        { '<leader>mp', '<cmd>MarkdownPreview<cr>',     ft = 'markdown', desc = 'Markdow preview (browser)' },
        { '<leader>mP', '<cmd>MarkdownPreviewStop<cr>', ft = 'markdown', desc = 'Markdow preview stop' },
    }
}
