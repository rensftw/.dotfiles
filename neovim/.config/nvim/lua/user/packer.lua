---@diagnostic disable: different-requires
local fn = vim.fn
local install_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
local is_bootstrap = false

-- Automatically install Packer
if fn.empty(fn.glob(install_path)) > 0 then
    is_bootstrap = true
    vim.fn.execute('!git clone https://github.com/wbthomason/packer.nvim ' .. install_path)
    vim.cmd [[packadd packer.nvim]]
end

require('packer').startup({
    function(use)
        -- Packer can manage itself
        use 'wbthomason/packer.nvim'

        -- Dashboard
        use 'goolord/alpha-nvim'

        -- Undotree
        use 'mbbill/undotree'

        -- Treesitter (AST-based syntax highlighting)
        use { -- Highlight, edit, and navigate code
            'nvim-treesitter/nvim-treesitter',
            run = function()
                pcall(require('nvim-treesitter.install').update { with_sync = true })
            end,
        }
        use 'nvim-treesitter/nvim-treesitter-textobjects'
        use 'nvim-treesitter/nvim-treesitter-context'

        -- Telescope
        use 'kyazdani42/nvim-web-devicons'
        use 'nvim-lua/plenary.nvim'
        use 'nvim-telescope/telescope.nvim'
        use { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' }

        -- LSP
        use 'neovim/nvim-lspconfig'
        use 'jose-elias-alvarez/null-ls.nvim'
        use 'nvimdev/lspsaga.nvim'
        -- Show LSP status during startup
        use 'j-hui/fidget.nvim'

        -- Autocomplete
        use 'hrsh7th/nvim-cmp'
        -- completion sources:
        use 'hrsh7th/cmp-nvim-lsp'
        use 'hrsh7th/cmp-nvim-lua'
        use 'hrsh7th/cmp-buffer'
        use 'hrsh7th/cmp-path'
        use 'hrsh7th/cmp-cmdline'
        use 'rcarriga/cmp-dap'

        -- DAP / Debugging
        use 'mfussenegger/nvim-dap'
        use 'nvim-telescope/telescope-dap.nvim'
        use 'rcarriga/nvim-dap-ui'
        use 'theHamsta/nvim-dap-virtual-text'

        -- Manage LSP and DAP dependencies
        use 'folke/neodev.nvim'
        use {
            'williamboman/mason.nvim',
            'williamboman/mason-lspconfig.nvim',
            'jayp0521/mason-nvim-dap.nvim',
        }

        -- ChatGPT
        use({
            'jackMort/ChatGPT.nvim',
            requires = {
                'MunifTanjim/nui.nvim',
            }
        })

        -- Session management
        use 'tpope/vim-obsession'

        -- File explorer
        use 'kyazdani42/nvim-tree.lua'
        use 'luukvbaal/nnn.nvim'

        -- Haproon
        use 'ThePrimeagen/harpoon'

        -- Add indent guides
        use 'lukas-reineke/indent-blankline.nvim'

        -- Markdown aligning
        use 'junegunn/vim-easy-align'

        -- JSON schemas
        use 'b0o/schemastore.nvim'

        -- Snippets
        use 'L3MON4D3/LuaSnip'
        use 'saadparwaiz1/cmp_luasnip'

        -- Documentation comments
        use { 'kkoomen/vim-doge', run = ':call doge#install()' }

        -- Git utilities
        use 'tpope/vim-fugitive'
        use 'lewis6991/gitsigns.nvim'

        -- Comment stuff out
        use 'numToStr/Comment.nvim'

        -- Autopairs
        use 'windwp/nvim-autopairs'

        -- Change, delete, add surroundings (parentheses, brackets, quotes, tags)
        use 'tpope/vim-surround'

        -- Mappings for complementary commands like ]q, [q, etc
        use 'tpope/vim-unimpaired'

        -- Allow vim-surround and vim-unimpaired commands to be repeated with .
        use 'tpope/vim-repeat'

        -- Add indentation that closely matches PEP 8
        use 'vim-scripts/indentpython'

        -- Respect .editorconfig
        use 'editorconfig/editorconfig-vim'

        -- Feline
        use 'feline-nvim/feline.nvim'

        -- Themes
        use 'folke/tokyonight.nvim'
        use { 'catppuccin/nvim', as = 'catppuccin' }

        -- Colorizer for CSS files
        use 'norcalli/nvim-colorizer.lua'

        -- Markdown preview
        use { 'iamcco/markdown-preview.nvim', run = 'cd app && yarn install' }

        -- Seamless vim + tmux navigation
        use 'christoomey/vim-tmux-navigator'

        -- Automatically set up your configuration after cloning packer.nvim
        -- Put this at the end after all plugins
        if is_bootstrap then
            require('packer').sync()
        end
    end,
    config = {
        display = {
            prompt_border = 'rounded', -- Border style of prompt popups.
            working_sym = '',         -- The symbol for a plugin being installed/updated
            error_sym = '',           -- The symbol for a plugin with an error in installation/updating
            done_sym = '',            -- The symbol for a plugin which has completed installation/updating
            removed_sym = '',         -- The symbol for an unused plugin which was removed
            moved_sym = '',           -- The symbol for a plugin which was moved (e.g. from opt to start)
        }
    }
})

-- When we are bootstrapping a configuration, it doesn't
-- make sense to execute the rest of the init.lua.
--
-- You'll need to restart nvim, and then it will work.
if is_bootstrap then
    print '=================================='
    print '    Plugins are being installed'
    print '    Wait until Packer completes,'
    print '       then restart nvim'
    print '=================================='
    return
end
