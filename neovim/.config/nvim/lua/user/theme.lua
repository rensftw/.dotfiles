require('tokyonight').setup({
    style = 'night',
    lualine_bold = true,
    sidebars = { 'help', 'packer' },
    styles = {
        floats = 'normal'
    }
})

vim.cmd [[colorscheme tokyonight]]
