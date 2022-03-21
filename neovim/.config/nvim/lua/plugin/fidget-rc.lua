require('fidget').setup {
    text = {
        spinner = 'dots',        -- animation shown when tasks are ongoing
    },
    timer = {
        fidget_decay = 5000,     -- how long to keep around empty fidget, in ms
        task_decay = 2000,       -- how long to keep around completed task, in ms
    }
}
