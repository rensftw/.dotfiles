local list = {
    { key = { '<CR>', 'l' }, action = 'edit' },
    { key = { '<BS>', 'h' }, action = 'close_node' },
    { key = {'<C-]>' }, action = 'cd' },
    { key = '<Tab>', action = 'preview' },
    { key = 'R', action = 'refresh' },
    { key = 'a', action = 'create' },
    { key = 'dd', action = 'remove' },
    { key = 'cw', action = 'rename' },
    { key = 'x', action = 'cut' },
    { key = 'yy', action = 'copy' },
    { key = 'p', action = 'paste' },
    { key = 'yp', action = 'copy_path' },
    { key = 'gy', action = 'copy_absolute_path' },
    { key = '?', action = 'toggle_help' },
    { key = '-', action = '' }, -- Overwrite default mapping for -, so it can be used for resizing the tree split
}

require 'nvim-tree'.setup {
    auto_reload_on_write = true,
    git = {
        ignore = false
    },
    update_focused_file = {
        enable = true
    },
    view = {
        width = 60,
        mappings = {
            list = list
        }
    },
    renderer = {
        icons = {
            glyphs = {
                folder = {
                    default = '',
                    open = '',
                }
            }
        }
    }
}
