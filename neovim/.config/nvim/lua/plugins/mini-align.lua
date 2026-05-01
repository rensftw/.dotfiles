return {
    'nvim-mini/mini.align',
    lazy = true,
    keys = {
        { mode = { 'n', 'x' }, 'ga', desc = 'Align (mini.align)' },
        { mode = { 'n', 'x' }, 'gA', desc = 'Align with preview (mini.align)' },
    },
    config = function()
        -- Defaults bind `ga` (interactive align) and `gA` (with preview).
        require('mini.align').setup({})
    end,
}
