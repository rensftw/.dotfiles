return {
    'ThePrimeagen/harpoon',
    lazy = true,
    keys = {
        { mode = { 'n' }, '<leader>ha', function() require('harpoon.mark').add_file() end },
        { mode = { 'n' }, '<leader>hh', function() require('harpoon.ui').toggle_quick_menu() end },
        { mode = { 'n' }, '<leader>1',  function() require('harpoon.ui').nav_file(1) end, },
        { mode = { 'n' }, '<leader>2',  function() require('harpoon.ui').nav_file(2) end, },
        { mode = { 'n' }, '<leader>3',  function() require('harpoon.ui').nav_file(3) end, },
        { mode = { 'n' }, '<leader>4',  function() require('harpoon.ui').nav_file(4) end, },
    }
}
