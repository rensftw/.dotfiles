-- Documentation comments
vim.g.doge_mapping = '<leader>jd'
vim.g.doge_filetype_aliases = {
    javascript = {
        -- 'vue', -- https://github.com/kkoomen/vim-doge/issues/324
        'javascript.jsx',
        'javascriptreact',
        'javascript.tsx',
        'typescriptreact',
        'typescript',
        'typescript.tsx',
    }
}
vim.g.doge_javascript_settings = {
    destructuring_props = 1,
    omit_redundant_param_types = 0,
}
