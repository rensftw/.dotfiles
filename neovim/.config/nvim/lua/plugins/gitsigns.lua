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
                add          = { hl = 'GitSignsAdd',    text = '▌', numhl = 'GitSignsAddNr',    linehl = 'GitSignsAddLn'    },
                untracked    = { hl = 'GitSignsAdd',    text = '▌', numhl = 'GitSignsAddNr',    linehl = 'GitSignsAddLn'    },
                change       = { hl = 'GitSignsChange', text = '▌', numhl = 'GitSignsChangeNr', linehl = 'GitSignsChangeLn' },
                delete       = { hl = 'GitSignsDelete', text = '▌', numhl = 'GitSignsDeleteNr', linehl = 'GitSignsDeleteLn' },
                topdelete    = { hl = 'GitSignsDelete', text = '▔', numhl = 'GitSignsDeleteNr', linehl = 'GitSignsDeleteLn' },
                changedelete = { hl = 'GitSignsChange', text = '~', numhl = 'GitSignsChangeNr', linehl = 'GitSignsChangeLn' },
            },
            current_line_blame = false,     -- Toggle with `:Gitsigns toggle_current_line_blame`
        }
    end
}
