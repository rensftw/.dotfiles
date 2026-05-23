return {
    'christoomey/vim-tmux-navigator',
    lazy = true,
    cmd = {
        'TmuxNavigateLeft',
        'TmuxNavigateDown',
        'TmuxNavigateUp',
        'TmuxNavigateRight',
        'TmuxNavigatePrevious',
    },
    keys = {
        { mode = { 'n' }, '<C-h>', '<cmd>TmuxNavigateLeft<CR>',     desc = 'Navigate left (tmux-aware)' },
        { mode = { 'n' }, '<C-j>', '<cmd>TmuxNavigateDown<CR>',     desc = 'Navigate down (tmux-aware)' },
        { mode = { 'n' }, '<C-k>', '<cmd>TmuxNavigateUp<CR>',       desc = 'Navigate up (tmux-aware)' },
        { mode = { 'n' }, '<C-l>', '<cmd>TmuxNavigateRight<CR>',    desc = 'Navigate right (tmux-aware)' },
        { mode = { 'n' }, '<C-\\>', '<cmd>TmuxNavigatePrevious<CR>', desc = 'Navigate previous tmux pane' },
        { mode = { 't' }, '<C-h>', '<C-\\><C-n><cmd>TmuxNavigateLeft<CR>',     desc = 'Navigate left (tmux-aware)' },
        { mode = { 't' }, '<C-j>', '<C-\\><C-n><cmd>TmuxNavigateDown<CR>',     desc = 'Navigate down (tmux-aware)' },
        { mode = { 't' }, '<C-k>', '<C-\\><C-n><cmd>TmuxNavigateUp<CR>',       desc = 'Navigate up (tmux-aware)' },
        { mode = { 't' }, '<C-l>', '<C-\\><C-n><cmd>TmuxNavigateRight<CR>',    desc = 'Navigate right (tmux-aware)' },
        { mode = { 't' }, '<C-\\>', '<C-\\><C-n><cmd>TmuxNavigatePrevious<CR>', desc = 'Navigate previous tmux pane' },
    },
    -- This Vimscript plugin reads g: options while loading, so set them before
    -- the lazy-loaded command/key stubs source the plugin.
    init = function()
        -- Write all buffers before navigating from Vim to tmux pane
        vim.g.tmux_navigator_save_on_switch = 2

        -- Disable tmux navigator when zooming the Vim pane
        vim.g.tmux_navigator_disable_when_zoomed = 1
    end,
}
