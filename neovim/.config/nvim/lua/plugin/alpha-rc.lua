local alpha = require('alpha')
local fortune = require('alpha.fortune')
local if_nil = vim.F.if_nil

local section = {}
local plugins_count = vim.fn.len(vim.fn.globpath('~/.local/share/nvim/site/pack/packer/start', '*', 0, 1))
local plugins_info = '   ' .. plugins_count .. ' plugins loaded'
local version = vim.version()
local nvim_version_info = '   ' .. version.major .. '.' .. version.minor .. '.' .. version.patch
--- @param sc string
--- @param txt string
--- @param keybind string optional
--- @param keybind_opts table optional
local function button(sc, txt, keybind, keybind_opts)
    local sc_ = sc:gsub('%s', ''):gsub('SPC', '<leader>')

    local opts = {
        position = 'center',
        shortcut = sc,
        cursor = 5,
        width = 50,
        align_shortcut = 'right',
        hl_shortcut = 'Keyword',
    }
    if keybind then
        keybind_opts = if_nil(keybind_opts, { noremap = true, silent = true, nowait = true })
        opts.keymap = { 'n', sc_, keybind, keybind_opts }
    end

    local function on_press()
        local key = vim.api.nvim_replace_termcodes(sc_ .. '<Ignore>', true, false, true)
        vim.api.nvim_feedkeys(key, 'normal', false)
    end

    return {
        type = 'button',
        val = txt,
        on_press = on_press,
        opts = opts,
    }
end

-- Set header
section.header = { type = 'text', opts = { position = 'center', hl = 'Type' } }
section.header.val = {
    '                                                     ',
    '  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ',
    '  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ',
    '  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ',
    '  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ',
    '  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ',
    '  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ',
    '                                                     ',
}

section.subtitle = { type = 'text', opts = { position = 'center', hl = 'Type' } }
section.subtitle.val = nvim_version_info .. plugins_info

-- Set menu
section.buttons = { type = 'group', opts = { spacing = 1 } }
section.buttons.val = {
    button('n', '  New file', ':ene <BAR> startinsert <CR>', nil),
    button('f', '  Find file', '<cmd>lua require("telescope.builtin").find_files({hidden = true, previewer = false})<CR>', nil),
    -- button('r', '↺  Recent', ':Telescope oldfiles previewer=false<CR>', nil),
    button('r', '↺  Recent', '<cmd>lua require("telescope.builtin").oldfiles({initial_mode = "normal", previewer = false})<CR>', nil),
    button('u', '  Update plugins', '<cmd>PackerSync<CR>', nil),
    button('s', '  Settings', ':e $VIMRC_LOCATION | :cd %:p:h | split . | wincmd k | pwd<CR>', nil),
    button('q', '✖  Quit NVIM', ':qa<CR>', nil),
}

section.footer = { type = 'text', opts = { position = 'center', hl = 'Number' } }
section.footer.val = fortune()

local config = {
    layout = {
        { type = 'padding', val = 2 },
        section.header,
        { type = 'padding', val = 1 },
        section.subtitle,
        { type = 'padding', val = 2 },
        section.buttons,
        section.footer
    },
    opts = {
        margin = 5
    }
}

-- Send config to alpha
alpha.setup(config)

-- Disable folding on alpha buffer
vim.cmd([[autocmd FileType alpha setlocal nofoldenable]])
