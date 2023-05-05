local function on_attach(bufnr)
    local api = require('nvim-tree.api')

    local function opts(desc)
        return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
    end

    vim.keymap.set('n', '<C-v>', api.node.open.vertical,         opts('Open: Vertical Split'))
    vim.keymap.set('n', '<C-x>', api.node.open.horizontal,       opts('Open: Horizontal Split'))
    vim.keymap.set('n', '<C-k>', api.node.show_info_popup,       opts('Info'))
    vim.keymap.set('n', '<CR>',  api.node.open.edit,             opts('Open'))
    vim.keymap.set('n', 'l',     api.node.open.edit,             opts('Open'))
    vim.keymap.set('n', '<BS>',  api.node.navigate.parent_close, opts('Close Directory'))
    vim.keymap.set('n', 'h',     api.node.navigate.parent_close, opts('Close Directory'))
    vim.keymap.set('n', '<Tab>', api.node.open.preview,          opts('Open Preview'))
    vim.keymap.set('n', 'R',     api.tree.reload,                opts('Refresh'))
    vim.keymap.set('n', 'a',     api.fs.create,                  opts('Create'))
    vim.keymap.set('n', 'dd',    api.fs.remove,                  opts('Delete'))
    vim.keymap.set('n', 'cw',    api.fs.rename,                  opts('Rename'))
    vim.keymap.set('n', 'x',     api.fs.cut,                     opts('Cut'))
    vim.keymap.set('n', 'yy',    api.fs.copy.node,               opts('Copy'))
    vim.keymap.set('n', 'p',     api.fs.paste,                   opts('Paste'))
    vim.keymap.set('n', 'yp',    api.fs.copy.relative_path,      opts('Copy Relative Path'))
    vim.keymap.set('n', '?',     api.tree.toggle_help,           opts('Help'))
    vim.keymap.set('n', 'F',     api.live_filter.clear,          opts('Clean Filter'))
    vim.keymap.set('n', 'f',     api.live_filter.start,          opts('Filter'))
    -- Do not add mapping for -, so it can be used for resizing tree split
    -- vim.keymap.set('n', '-',     function()end,                  opts('Up'))

end

require 'nvim-tree'.setup {
    on_attach = on_attach,
    auto_reload_on_write = true,
    git = {
        ignore = false
    },
    update_focused_file = {
        enable = true
    },
    view = {
        width = 45,
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
