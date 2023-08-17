local builtin = require('nnn').builtin
require('nnn').setup({
    picker = {
        style = {
            border = 'rounded'
        },
        -- -a: auto-setup temporary NNN_FIFO (described in ENVIRONMENT section)
        -- -d: detail mode
        -- -H: show hidden files
        -- -P: specify plugin key to run
        cmd = 'tmux new-session nnn -a -d -H -P=preview-tui',
        session = 'shared',
        -- whether to fullscreen picker window when current tab is empty
        fullscreen = false,
    },
    mappings = {
        { '<C-t>', builtin.open_in_tab },
        { '<C-x>', builtin.open_in_split },
        { '<C-v>', builtin.open_in_vsplit },
        { '<C-y>', builtin.copy_to_clipboard },
        { '<C-p>', builtin.cd_to_path },
        { '<C-e>', builtin.populate_cmdline },
    }
})
