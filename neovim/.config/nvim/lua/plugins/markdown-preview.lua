return {
    'iamcco/markdown-preview.nvim',
    enabled = true,
    cmd = {
        'MarkdownPreviewToggle',
        'MarkdownPreview',
        'MarkdownPreviewStop',
    },
    ft = { 'markdown' },
    build = function() 
        vim.fn['mkdp#util#install']() 
    end,
    init = function ()
       vim.g.mkdp_auto_close = 0            -- keep preview open when switching buffers
       vim.g.theme = 'dark'
    end,
    keys = {
        { '<leader>mp', '<cmd>MarkdownPreviewToggle<cr>', ft = 'markdown', desc = 'Markdow preview (browser)'}
    }
}
