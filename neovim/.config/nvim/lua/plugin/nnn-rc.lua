local builtin = require('nnn').builtin
require('nnn').setup({
    picker = {
        style = {
            border = 'rounded'
        },
        fullscreen = false, -- whether to fullscreen picker window when current tab is empty
    },
    mappings = {
        { '<C-t>', builtin.open_in_tab },
        { '<C-x>', builtin.open_in_split },
        { '<C-v>', builtin.open_in_vsplit },
        { '<C-p>', builtin.open_in_preview },
        { 'y', builtin.copy_to_clipboard },
        { '<C-w>', builtin.cd_to_path },
        { '<C-e>', builtin.populate_cmdline },
    }
})
