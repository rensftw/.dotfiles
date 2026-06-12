return {
    'nvim-mini/mini.surround',
    lazy = true,
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
        -- Use mini.surround's native defaults: sa (add), sd (delete), sr (replace)
        require('mini.surround').setup({
            -- Match vim-surround's "find next pair if not currently inside one"
            -- behaviour. mini's default 'cover' is stricter (cursor must be
            -- inside the pair); 'cover_or_next' falls back to the next pair.
            search_method = 'cover_or_next',
        })
    end,
}
