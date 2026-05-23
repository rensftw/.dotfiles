return {
    'windwp/nvim-ts-autotag',
    lazy = true,
    event = 'InsertEnter',
    -- Auto-close and auto-rename HTML/JSX/TSX/Vue/Svelte/Astro tags using
    -- treesitter. When you type `>` to close an opening tag (e.g. `<div>`),
    -- it inserts the matching closing tag (`</div>`) and parks the cursor
    -- between them. When you rename one half of a tag pair, it renames the
    -- other half.
    --
    -- Distinct from mini.pairs: mini.pairs handles balanced-quote / bracket
    -- pairs (`()`, `[]`, `{}`, `''`, `""`, `` `` ``). ts-autotag handles HTML
    -- tag pairs. The two are complementary, not competing.
    --
    -- Doesn't depend on nvim-treesitter (the plugin); uses `vim.treesitter.*`
    -- core APIs against whatever parsers are installed by tree-sitter-manager.
    config = function()
        require('nvim-ts-autotag').setup({})
    end,
}
