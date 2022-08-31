---@diagnostic disable: different-requires
local fn = vim.fn
local install_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'

-- Automatically install Packer
if fn.empty(fn.glob(install_path)) > 0 then
    Packer_bootstrap = fn.system({
        'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim',
        install_path
    })
end

return require('packer').startup(function(use)
    -- Packer can manage itself
    use 'wbthomason/packer.nvim'

    -- Dashboard
    use 'goolord/alpha-nvim'

    -- Treesitter (AST-based syntax highlighting)
    use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' }

    -- Telescope
    use 'kyazdani42/nvim-web-devicons'
    use 'nvim-lua/plenary.nvim'
    use 'nvim-telescope/telescope.nvim'
    use { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' }

    -- LSP
    use 'neovim/nvim-lspconfig'
    use 'tami5/lspsaga.nvim'
    use 'hrsh7th/nvim-cmp'
    -- completion sources:
    use 'hrsh7th/cmp-nvim-lsp'
    use 'hrsh7th/cmp-nvim-lua'
    use 'hrsh7th/cmp-buffer'
    use 'hrsh7th/cmp-path'
    use 'hrsh7th/cmp-cmdline'
    use 'rcarriga/cmp-dap'

    -- Show LSP status during startup
    use 'j-hui/fidget.nvim'

    -- DAP / Debugging
    use 'mfussenegger/nvim-dap'
    use 'nvim-telescope/telescope-dap.nvim'
    use 'rcarriga/nvim-dap-ui'
    use 'theHamsta/nvim-dap-virtual-text'
    use 'mxsdev/nvim-dap-vscode-js'
    use {
        'microsoft/vscode-js-debug',
        opt = true,
        run = 'npm install --legacy-peer-deps && npm run compile'
    }

    -- Session management
    use 'tpope/vim-obsession'

    -- File explorer
    use 'kyazdani42/nvim-tree.lua'

    -- Symbols
    use 'simrat39/symbols-outline.nvim'

    -- Add indent guides
    use 'lukas-reineke/indent-blankline.nvim'

    -- Smooth scrolling
    use 'karb94/neoscroll.nvim'

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

    -- Briefly highlight which text was yanked
    use 'machakann/vim-highlightedyank'

    -- Add indentation that closely matches PEP 8
    use 'vim-scripts/indentpython'

    -- Respect .editorconfig
    use 'editorconfig/editorconfig-vim'

    -- Lualine
    use 'nvim-lualine/lualine.nvim'

    -- Themes
    use 'folke/tokyonight.nvim'

    -- Colorizer for CSS files
    use 'norcalli/nvim-colorizer.lua'

    -- Markdown preview
    use { 'iamcco/markdown-preview.nvim', run = 'cd app && yarn install' }

    -- Seamless vim + tmux navigation
    use 'christoomey/vim-tmux-navigator'

    -- Automatically set up your configuration after cloning packer.nvim
    -- Put this at the end after all plugins
    if Packer_bootstrap then
        require('packer').sync()
    end
end)
