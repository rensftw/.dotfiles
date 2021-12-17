require('gitsigns').setup {
  signs = {
    add          = {hl = 'GitSignsAdd'   , text = '│', numhl='GitSignsAddNr'   , linehl='GitSignsAddLn'},
    change       = {hl = 'GitSignsChange', text = '│', numhl='GitSignsChangeNr', linehl='GitSignsChangeLn'},
    delete       = {hl = 'GitSignsDelete', text = '│', numhl='GitSignsDeleteNr', linehl='GitSignsDeleteLn'},
    topdelete    = {hl = 'GitSignsDelete', text = '‾', numhl='GitSignsDeleteNr', linehl='GitSignsDeleteLn'},
    changedelete = {hl = 'GitSignsChange', text = '~', numhl='GitSignsChangeNr', linehl='GitSignsChangeLn'},
  },
  keymaps = {
    noremap = true,
    ['n ]h'] = { expr = true, "&diff ? ']h' : '<cmd>Gitsigns next_hunk<CR>'"},
    ['n [h'] = { expr = true, "&diff ? '[h' : '<cmd>Gitsigns prev_hunk<CR>'"},

    ['n <leader>ha'] = '<cmd>Gitsigns stage_hunk<CR>',
    ['v <leader>ha'] = ':Gitsigns stage_hunk<CR>',
    ['n <leader>hu'] = '<cmd>Gitsigns reset_hunk<CR>',
    ['v <leader>hu'] = ':Gitsigns reset_hunk<CR>',
    ['n <leader>hp'] = '<cmd>Gitsigns preview_hunk<CR>',
    ['n <leader>hA'] = '<cmd>Gitsigns stage_buffer<CR>',
    ['n <leader>hU'] = '<cmd>Gitsigns reset_buffer<CR>',
    ['n <leader>gb'] = '<cmd>Gitsigns toggle_current_line_blame<CR>',
  },
  current_line_blame = false, -- Toggle with `:Gitsigns toggle_current_line_blame`
}

