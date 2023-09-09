return {
    'j-hui/fidget.nvim',
    tag = 'legacy',
    lazy = true,
    event = 'LspAttach',
    enabled = true,
    config = function()
        require('fidget').setup {
            text = {
                spinner = 'dots', -- animation shown when tasks are ongoing
            },
            timer = {
                fidget_decay = 6000, -- how long to keep around empty fidget, in ms
                task_decay = 3000,   -- how long to keep around completed task, in ms
            },
            window = {
                relative = 'win',   -- where to anchor, either 'win' or 'editor'
                blend = 0,          -- &winblend for the window
                border = 'rounded', -- style of border for the fidget window
            },
        }
    end
}
