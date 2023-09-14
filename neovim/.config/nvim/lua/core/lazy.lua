local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        'git',
        'clone',
        '--filter=blob:none',
        'https://github.com/folke/lazy.nvim.git',
        '--branch=stable', -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

local plugins = {
    { import = 'plugins' },
    { import = 'statusline.feline' },
    { import = 'lsp' },
    { import = 'dap' },
}

local options = {
    install = {
        colorscheme = { 'tokyonight' },
    },
    ui = {
        border = 'rounded',
        title = 'lazy.nvim',
    },
    checker = {
        enabled = true,          -- enable statusline plugin
        notify = false,          -- do not notify when there are updates
        frequency = 3 * 60 * 60, -- check for updates every 3 hours (provided in seconds)
    },
    change_detection = {
        enabled = true,
        notify = true
    }
}

require('lazy').setup(plugins, options)
