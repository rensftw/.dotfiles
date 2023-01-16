local saga = require 'lspsaga'

-- Diagnostic icons defined in lua/lsp/native-settings.lua
local error_icon = vim.fn.sign_getdefined('DiagnosticSignError')[1].text
local warn_icon = vim.fn.sign_getdefined('DiagnosticSignWarn')[1].text
local info_icon = vim.fn.sign_getdefined('DiagnosticSignInfo')[1].text
local hint_icon = vim.fn.sign_getdefined('DiagnosticSignHint')[1].text

saga.setup {
    border_style = 'rounded',
    diagnostic_header = { error_icon, warn_icon, info_icon, hint_icon },
    code_action_icon = ' ',
    code_action_num_shortcut = true,
    max_preview_lines = 20,
    finder_icons = {
      def = '  ',
      ref = '⌨ ',
      link = '  ',
    },
    finder_action_keys = {
        open = {'o', '<CR>'},
        vsplit = 's',
        split = 'i',
        tabe = 't',
        quit = {'q', '<ESC>'},
    },
    code_action_keys = {
        quit = 'q',
        exec = '<CR>',
    },
    rename_in_select = true,
    show_outline = {
        win_position = 'right',
        --set special filetype win that outline window split.like NvimTree neotree
        -- defx, db_ui
        win_with = '',
        win_width = 30,
        auto_enter = true,
        auto_preview = true,
        virt_text = '┃',
        jump_key = 'o',
        -- auto refresh when change buffer
        auto_refresh = true,
    },
    move_in_saga = { prev = '<C-j>', next = '<C-k>' },
}
