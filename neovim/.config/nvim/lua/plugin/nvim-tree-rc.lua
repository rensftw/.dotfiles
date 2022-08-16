local tree_cb = require 'nvim-tree.config'.nvim_tree_callback


local list = {
    { key = { '<CR>', 'l', '<2-LeftMouse>' }, cb = tree_cb('edit') },
    { key = { '<BS>', 'h' }, cb = tree_cb('close_node') },
    { key = { '<2-RightMouse>', '<C-]>' }, cb = tree_cb('cd') },
    { key = '<Tab>', cb = tree_cb('preview') },
    { key = 'R', cb = tree_cb('refresh') },
    { key = 'a', cb = tree_cb('create') },
    { key = 'd', cb = tree_cb('remove') },
    { key = 'D', cb = tree_cb('trash') },
    { key = 'r', cb = tree_cb('rename') },
    { key = 'x', cb = tree_cb('cut') },
    { key = 'c', cb = tree_cb('copy') },
    { key = 'p', cb = tree_cb('paste') },
    { key = 'y', cb = tree_cb('copy_name') },
    { key = 'Y', cb = tree_cb('copy_path') },
    { key = 'gy', cb = tree_cb('copy_absolute_path') },
    { key = '[h', cb = tree_cb('prev_git_item') },
    { key = ']h', cb = tree_cb('next_git_item') },
    { key = '?', cb = tree_cb('toggle_help') },
    { key = '-', cb = tree_cb('') }, -- Overwrite default mapping for -, so it can be used for resizing the tree split
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
