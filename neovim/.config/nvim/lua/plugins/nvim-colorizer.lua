return {
    'catgoose/nvim-colorizer.lua',
    event = { 'BufReadPost', 'BufNewFile' },
    config = function()
        require('colorizer').setup({
            user_default_options = {
                names    = true, -- CSS named colours (red, rebeccapurple, …)
                RRGGBBAA = true, -- #RRGGBBAA
                rgb_fn   = true, -- rgb() / rgba()
                hsl_fn   = true, -- hsl() / hsla()
                css      = true, -- enable the broad CSS grammar
                css_fn   = true, -- enable CSS function forms
            },
        })
    end,
}
