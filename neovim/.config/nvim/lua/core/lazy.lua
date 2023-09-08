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
    --[[ UI ]]
    -- Themes
    { { require('plugins.tokyonight') } },
    { { require('plugins.catpuccin') } },
    -- Icons
    { { require('plugins.nvim-web-devicons') } },
    -- Statusline + Winbar
    { { require('statusline.feline') } },
    -- Dashboard
    { { require('plugins.alpha') } },

    --[[ Editor ]]
    -- Treesitter (AST-based syntax highlighting)
    { { require('plugins.nvim-treesitter') } },
    -- Telescope
    { { require('plugins.telescope') } },
    -- Manage external dependencies
    { { require('plugins.mason') } },
    { { require('plugins.mason-lspconfig') } },

    -- Utils
    { { require('plugins.plenary') } },
    { { require('plugins.nui') } },

    -- Notifications
    -- TODO: choose one of the 2
    { { require('plugins.fidget') } },
    { { require('plugins.noice') } },

    --[[ LSP ]]
    { { require('lsp.lspsaga') } },
    { { require('lsp.nvim-lsp-config') } },

    --[[ Autocomplete ]]
    { { require('plugins.luasnip') } }, -- Snippet engine
    { { require('plugins.nvim-cmp') } },

    --[[ Debugger ]]
    { { require('dap.dap') } },
    { { require('dap.dap-ui') } },
    { { require('dap.dap-virtual-text') } },
    { { require('dap.mason-dap') } },
    { { require('dap.telescope-dap') } },

    -- ChatGPT
    { { require('plugins.chatgpt') } },

    -- Undotree
    { { require('plugins.undotree') } },

    -- Session management
    { { require('plugins.vim-obsession') } },

    -- File explorer
    { { require('plugins.nvim-tree') } },
    { { require('plugins.nnn') } },

    -- Harpoon
    { { require('plugins.harpoon') } },

    -- Add indent guides
    { { require('plugins.indent-blankline') } },

    -- Markdown aligning
    { { require('plugins.easy-align') } },

    -- Git utilities
    { { require('plugins.vim-fugitive') } },
    { { require('plugins.gitsigns') } },

    -- Comment stuff out
    { { require('plugins.comment') } },

    -- Autopairs
    { { require('plugins.autopairs') } },

    -- Change, delete, add surroundings (parentheses, brackets, quotes, tags)
    { { require('plugins.vim-surround') } },

    -- Mappings for complementary commands like ]q, [q, etc
    { { require('plugins.vim-unimpaired') } },

    -- Allow vim-surround and vim-unimpaired commands to be repeated with .
    { { require('plugins.vim-repeat') } },

    -- Colorizer for CSS files
    { { require('plugins.nvim-colorizer') } },

    -- Seamless vim + tmux navigation
    { { require('plugins.vim-tmux-navigator') } },
}

local options = {
    ui = {
        border = 'rounded',
        title = 'lazy.nvim',
    },
    checker = {
        enabled = true, -- enable statusline plugin
        notify = false, -- do not notify when there are updates
    },
    change_detection = {
        enabled = true,
        notify = true
    }
}

require('lazy').setup(plugins, options)
