return {
    'nvim-mini/mini.surround',
    lazy = true,
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
        -- vim-surround-compatible keymaps preserve existing muscle memory:
        --   ysiw"   add surround around inner word
        --   cs"'    change " to '
        --   ds"     delete surrounding "
        --   S{      (visual mode) wrap selection
        --
        -- To switch to mini's native defaults (sa/sd/sr), drop the `mappings`
        -- table.
        require('mini.surround').setup({
            mappings = {
                add            = 'ys',
                delete         = 'ds',
                replace        = 'cs',
                find           = '',
                find_left      = '',
                highlight      = '',
                update_n_lines = '',
                suffix_last    = '',
                suffix_next    = '',
            },
            -- Match vim-surround's "find next pair if not currently inside one"
            -- behaviour. mini's default 'cover' is stricter (cursor must be
            -- inside the pair); 'cover_or_next' falls back to the next pair.
            search_method = 'cover_or_next',
        })
    end,
}
