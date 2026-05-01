return {
    'nvim-mini/mini.pairs',
    lazy = true,
    event = 'InsertEnter',
    config = function()
        -- Defaults autoclose (), [], {}, '', "", ``.
        require('mini.pairs').setup({})
    end,
}
