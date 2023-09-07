return {
    'numToStr/Comment.nvim',
    keys = {
        { 'gc', mode = { 'n', 'v', 'x' }, desc = 'Comment toggle linewise' },
        { 'gb', mode = { 'n', 'v', 'x' }, desc = 'Comment toggle blockwise' },
    },
    config = function()
        require 'Comment'.setup()
    end
}
