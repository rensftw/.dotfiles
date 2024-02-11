return {
    'iamcco/markdown-preview.nvim',
    lazy = true,
    ft = { 'markdown' },
    cmd = {
        'MarkdownPreviewToggle',
        'MarkdownPreview',
        'MarkdownPreviewStop',
    },
    build = 'cd app && yarn install',
}
