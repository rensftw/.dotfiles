return {
    'nvim-mini/mini.animate',
    version = false,
    enable = false,
    event = 'VeryLazy',
    config = function()
        local animate = require('mini.animate')
        local timing = animate.gen_timing.linear({
            duration = 8, -- ~120 Hz frame interval
            unit = 'step',
        })

        animate.setup({
            cursor = {
                timing = timing,
                path = animate.gen_path.line({
                    max_output_steps = 15, -- Cap long jumps at ~120 ms
                }),
            },
            scroll = {
                timing = timing,
                subscroll = animate.gen_subscroll.equal({
                    max_output_steps = 20, -- Cap long scrolls at ~160 ms
                }),
            },
            resize = { enable = false },
            open = { enable = true },
            close = { enable = true },
        })
    end,
}
