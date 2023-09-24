return {
    'epwalsh/obsidian.nvim',
    lazy = true,
    event = {
        -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
        'BufReadPre ' .. vim.fn.expand('$OBSIDIAN_LOCATION') .. '/**.md',
        'BufNewFile ' .. vim.fn.expand('$OBSIDIAN_LOCATION') .. '/**.md',
    },
    dependencies = {
        'nvim-lua/plenary.nvim',
        'hrsh7th/nvim-cmp',
        'nvim-telescope/telescope.nvim',
    },
    config = function()
        require('obsidian').setup({
            dir = vim.fn.expand('$OBSIDIAN_LOCATION'),
            mappings = {
                -- Overrides the 'gf' mapping to work on markdown/wiki links within your vault.
                ['gf'] = require('obsidian.mapping').gf_passthrough(),
            },
        })
    end
}
