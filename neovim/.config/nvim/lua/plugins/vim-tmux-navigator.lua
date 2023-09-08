return {
    'christoomey/vim-tmux-navigator',
    lazy = false,
    config = function()
        -- Write all buffers before navigating from Vim to tmux pane
        vim.g.tmux_navigator_save_on_switch = 2

        -- Disable tmux navigator when zooming the Vim pane
        vim.g.tmux_navigator_disable_when_zoomed = 1
    end
}
