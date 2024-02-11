return {
    'junegunn/vim-easy-align',
    lazy = true,
    event = 'VeryLazy',
    cmd = {'EasyAlign'},
    keys = {
        -- Start interactive EasyAlign in normal (e.g. gaip) or visual mode (e.g. vipga)
        { mode = { 'x' }, 'ga', '<Plug>(EasyAlign)' },
        { mode = { 'v' }, 'ga', '<Plug>(EasyAlign)' },
    }
}
