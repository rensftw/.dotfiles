--[[
-- Each treesitter grammar definers their own names for things.
-- More info: https://github.com/lukas-reineke/indent-blankline.nvim/issues/271
-- The following patterns cover JS/TS
--]]
vim.g.indent_blankline_context_patterns = {
    'class',
    'return',
    'function',
    'method',
    '^if',
    '^else',
    '^while',
    '^for',
    '^object',
    '^table',
    'block',
    'arguments',
    'jsx_element',
    'jsx_self_closing_element',
    'try_statement',
    'catch_clause',
    'import_statement',
    'operation_type'
}

vim.g.indent_blankline_buftype_exclude = { 'terminal' }
vim.g.indent_blankline_filetype_exclude = { 'alpha' }

require('indent_blankline').setup {
    space_char_blankline = " ",
    show_current_context = true,
    show_current_context_start = true,
    use_treesitter = true,
}
