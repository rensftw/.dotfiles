return {
    'iamcco/markdown-preview.nvim',
    lazy = true,
    event = 'VeryLazy',
    ft = { 'markdown' },
    cmd = {
        'MarkdownPreviewToggle',
        'MarkdownPreview',
        'MarkdownPreviewStop',
    },
    build = 'cd app && yarn install',
}
