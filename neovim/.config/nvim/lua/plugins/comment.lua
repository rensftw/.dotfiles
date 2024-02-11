return {
    'numToStr/Comment.nvim',
    lazy = true,
    keys = {
        { 'gc', mode = { 'n', 'v', 'x' }, desc = 'Comment toggle linewise' },
        { 'gb', mode = { 'n', 'v', 'x' }, desc = 'Comment toggle blockwise' },
    },
    config = function()
        require('Comment').setup({
            pre_hook = require('ts_context_commentstring.integrations.comment_nvim').create_pre_hook(),
        })
    end
}
