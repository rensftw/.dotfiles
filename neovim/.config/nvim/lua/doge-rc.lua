-- Documentation comments
vim.g.doge_mapping = '<leader>jd'
vim.g.doge_filetype_aliases = {
    javascript = {
        'vue',
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

