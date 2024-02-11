return {
    'ThePrimeagen/harpoon',
    lazy = true,
    event = 'VeryLazy',
    keys = function()
        local harpoon_ui = require('harpoon.ui')

        return {
            { mode = { 'n' }, '<leader>ha', function() require('harpoon.mark').add_file() end },
            { mode = { 'n' }, '<leader>hh', harpoon_ui.toggle_quick_menu },
            { mode = { 'n' }, '<leader>1',  function() harpoon_ui.nav_file(1) end, },
            { mode = { 'n' }, '<leader>2',  function() harpoon_ui.nav_file(2) end, },
            { mode = { 'n' }, '<leader>3',  function() harpoon_ui.nav_file(3) end, },
            { mode = { 'n' }, '<leader>4',  function() harpoon_ui.nav_file(4) end, },
        }
    end
}
