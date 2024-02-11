return {
    'mbbill/undotree',
    lazy = true,
    event = 'VeryLazy',
    keys = {
        { '<leader>u', ':UndotreeToggle<CR>' }
    },
    config = function()
        -- vim.g.undotree_WindowLayout = 3
        vim.g.undotree_SplitWidth = 50
        vim.g.undotree_DiffAutoOpen = 0
        vim.g.undotree_SetFocusWhenToggle = 1
        vim.g.undotree_RelativeTimestamp = 1
        vim.g.undotree_ShortIndicators = 1
    end
}
