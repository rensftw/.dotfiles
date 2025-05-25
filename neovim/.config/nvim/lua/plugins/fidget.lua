return {
    'j-hui/fidget.nvim',
    enabled = true,
    lazy = true,
    event = 'LspAttach',
    config = function()
        require('fidget').setup({
            -- Options related to LSP progress subsystem
            progress = {
                ignore = {}, -- List of LSP servers to ignore
                display = {
                    render_limit = 16, -- How many LSP messages to show at once
                    done_ttl = 5, -- How long a message should persist after completion
                    done_icon = ' ', -- Icon shown when all LSP progress tasks are complete
                    progress_icon = { pattern = 'dots', period = 1 }, -- Icon shown when LSP progress tasks are in progress
                },
            },

            -- Options related to notification subsystem
            notification = {
                window = {
                    winblend = 0,       -- Background color opacity in the notification window
                    border = 'rounded', -- Border around the notification window
                },
            },
        })
    end
}
