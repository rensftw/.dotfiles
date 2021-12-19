local fn = vim.fn
local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'

-- Automatically install Packer
if fn.empty(fn.glob(install_path)) > 0 then
  packer_bootstrap = fn.system({
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
    use {'nvim-treesitter/nvim-treesitter', run = ':TSUpdate'}

    -- Telescope
    use 'kyazdani42/nvim-web-devicons'
    use 'nvim-lua/popup.nvim'
    use 'nvim-lua/plenary.nvim'
    use {'nvim-telescope/telescope-fzf-native.nvim', run = 'make'}
    use 'nvim-telescope/telescope.nvim'

    -- File explorer
    use 'kyazdani42/nvim-tree.lua'

    -- LSP
    use 'neovim/nvim-lspconfig'
    use 'tami5/lspsaga.nvim'
    use 'folke/trouble.nvim'
    use 'hrsh7th/nvim-cmp'
    -- completion sources:
    use 'hrsh7th/cmp-nvim-lsp'
    use 'hrsh7th/cmp-buffer'
    use 'hrsh7th/cmp-path'

    -- Snippets
    use 'SirVer/ultisnips'
    use 'quangnguyen30192/cmp-nvim-ultisnips'

    -- Documentation comments
    use {'kkoomen/vim-doge', run = ':call doge#install()'}

    -- Tags
    use 'ludovicchabant/vim-gutentags'

    -- Git utilities
    use 'tpope/vim-fugitive'
    use 'lewis6991/gitsigns.nvim'

    -- Toggle-able terminal
    use 'akinsho/toggleterm.nvim'

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
    use 'Luxed/ayu-vim'

    -- Colorizer for CSS files
    use 'norcalli/nvim-colorizer.lua'

    -- Remove distractions
    use 'junegunn/goyo.vim'

  -- Automatically set up your configuration after cloning packer.nvim
  -- Put this at the end after all plugins
  if packer_bootstrap then
    require('packer').sync()
  end
end)
