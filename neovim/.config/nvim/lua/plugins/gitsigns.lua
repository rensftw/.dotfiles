return {
    'lewis6991/gitsigns.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    keys = {
        -- Next/previous hunk
        { mode = { 'n' },    ']h',         '<cmd>Gitsigns next_hunk<CR>zz' },
        { mode = { 'n' },    '[h',         '<cmd>Gitsigns prev_hunk<CR>zz', },
        -- Preview hunk
        { mode = { 'n' },    '<leader>hp', '<cmd>Gitsigns preview_hunk<CR>', },
        -- Reset hunk
        { mode = { 'n', 'v' }, '<leader>hu', '<cmd>Gitsigns reset_hunk<CR>', },
        -- Reset changes in the entire buffer
        { mode = { 'n', 'v' }, '<leader>hU', '<cmd>Gitsigns reset_buffer<CR>', },
    },
    config = function()
        require('gitsigns').setup {
            signs = {
                add          = { text = '▌' },
                untracked    = { text = '▌' },
                change       = { text = '▌' },
                delete       = { text = '▌' },
                topdelete    = { text = '▔' },
                changedelete = { text = '~' },
            },
            current_line_blame = false,     -- Toggle with `:Gitsigns toggle_current_line_blame`
        }
    end
}
