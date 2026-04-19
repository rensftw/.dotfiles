return {
    'romus204/tree-sitter-manager.nvim',
    event = { 'BufReadPost', 'BufNewFile' },
    cmd = 'TSManager',
    dependencies = {
        { 'nvim-treesitter/nvim-treesitter-textobjects', branch = 'main' },
        'nvim-treesitter/nvim-treesitter-context',
        'JoosepAlviste/nvim-ts-context-commentstring',
    },
    config = function()

        require('tree-sitter-manager').setup({
            auto_install = true,
            border = 'rounded',
            ensure_installed = {
                'query',
                'bash',
                'c',
                'cmake',
                'comment',
                'cpp',
                'css',
                'dockerfile',
                'go',
                'graphql',
                'vimdoc',
                'html',
                'http',
                'javascript',
                'jsdoc',
                'json',
                'latex',
                'lua',
                'make',
                'markdown',
                'markdown_inline',
                'python',
                'regex',
                'ruby',
                'rust',
                'scss',
                'svelte',
                'toml',
                'tsx',
                'typescript',
                'vim',
                'vue',
                'yaml',
            },
        })

        require('treesitter-context').setup()

        require('nvim-treesitter-textobjects').setup({
            select = {
                lookahead = true,
                selection_modes = {
                    ['@parameter.outer'] = 'v',
                    ['@function.outer'] = 'V',
                    ['@class.outer'] = '<c-v>',
                },
            },
            move = {
                set_jumps = true,
            },
        })

        local ts_select = require('nvim-treesitter-textobjects.select')
        local ts_move = require('nvim-treesitter-textobjects.move')

        local function select(query) return function() ts_select.select_textobject(query, 'textobjects') end end
        local function goto_start(query) return function() ts_move.goto_next_start(query, 'textobjects') end end
        local function goto_end(query) return function() ts_move.goto_next_end(query, 'textobjects') end end
        local function goto_prev_start(query) return function() ts_move.goto_previous_start(query, 'textobjects') end end
        local function goto_prev_end(query) return function() ts_move.goto_previous_end(query, 'textobjects') end end

        vim.keymap.set({ 'x', 'o' }, 'aa', select('@parameter.outer'), { desc = 'around parameter' })
        vim.keymap.set({ 'x', 'o' }, 'ia', select('@parameter.inner'), { desc = 'inner parameter' })
        vim.keymap.set({ 'x', 'o' }, 'af', select('@function.outer'), { desc = 'around function' })
        vim.keymap.set({ 'x', 'o' }, 'if', select('@function.inner'), { desc = 'inner function' })
        vim.keymap.set({ 'x', 'o' }, 'ac', select('@class.outer'), { desc = 'around class' })
        vim.keymap.set({ 'x', 'o' }, 'ic', select('@class.inner'), { desc = 'inner class' })

        vim.keymap.set({ 'n', 'x', 'o' }, ']f', goto_start('@function.outer'), { desc = 'next function start' })
        vim.keymap.set({ 'n', 'x', 'o' }, ']F', goto_end('@function.outer'), { desc = 'next function end' })
        vim.keymap.set({ 'n', 'x', 'o' }, '[f', goto_prev_start('@function.outer'), { desc = 'previous function start' })
        vim.keymap.set({ 'n', 'x', 'o' }, '[F', goto_prev_end('@function.outer'), { desc = 'previous function end' })
        vim.keymap.set({ 'n', 'x', 'o' }, ']c', goto_start('@class.outer'), { desc = 'next class start' })
        vim.keymap.set({ 'n', 'x', 'o' }, ']C', goto_end('@class.outer'), { desc = 'next class end' })
        vim.keymap.set({ 'n', 'x', 'o' }, '[c', goto_prev_start('@class.outer'), { desc = 'previous class start' })
        vim.keymap.set({ 'n', 'x', 'o' }, '[C', goto_prev_end('@class.outer'), { desc = 'previous class end' })
    end,
}
