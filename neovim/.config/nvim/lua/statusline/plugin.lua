--[[
statusline.plugin

Registers the native statusline/winbar as a *virtual* lazy.nvim plugin
(no git repo — we just point `dir` at the config directory). Loading
via lazy gives us a clean place to:
  1. define dependencies (themes, devicons, obsession must be present),
  2. defer setup until :UiEnter so highlights see the active colorscheme,
  3. re-apply highlights on :ColorScheme.

Redraw strategy
---------------
Neovim re-evaluates %{%…%} on CursorMoved, BufEnter, ModeChanged, etc.,
so most segments refresh for free. The autocmds below add :redrawstatus
nudges for events that don't trigger a redraw on their own (diagnostic
counts, gitsigns updates, lazy update availability).
]]

return {
    name = 'native-statusline',
    dir = vim.fn.stdpath('config'),
    event = 'UiEnter',
    dependencies = {
        'folke/tokyonight.nvim',
        'nvim-tree/nvim-web-devicons',
        'tpope/vim-obsession',
    },
    config = function()
        require('statusline.highlights').setup()

        vim.go.statusline = "%{%v:lua.require'statusline.statusbar'.build()%}"
        vim.go.winbar     = "%{%v:lua.require'statusline.winbar'.build()%}"

        local grp = vim.api.nvim_create_augroup('StatuslineRedraw', { clear = true })
        local function redraw() vim.cmd('redrawstatus') end

        vim.api.nvim_create_autocmd({
            'DiagnosticChanged',
            'LspAttach',
            'LspDetach',
            'ModeChanged',
            'BufEnter',
            'BufWritePost',
        }, {
            group = grp,
            callback = function() vim.cmd('redrawstatus') end,
        })

        vim.api.nvim_create_autocmd('User', {
            group = grp,
            pattern = { 'GitSignsUpdate', 'LazyUpdate', 'LazyCheck' },
            callback = redraw,
        })

        vim.api.nvim_create_autocmd('ColorScheme', {
            group = grp,
            callback = function() require('statusline.highlights').setup() end,
        })
    end,
}
