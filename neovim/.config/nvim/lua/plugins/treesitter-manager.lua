return {
    'romus204/tree-sitter-manager.nvim',
    event = { 'BufReadPost', 'BufNewFile' },
    cmd = {
        'TSManager',
        'TSManagerUpdateAll',
    },
    dependencies = {
        'nvim-treesitter/nvim-treesitter-context',
        'JoosepAlviste/nvim-ts-context-commentstring',
    },
    config = function()
        require('tree-sitter-manager').setup({
            auto_install = true,
            border = 'rounded',
            -- `highlight = true` is intentionally omitted — it's broken for
            -- filetypes whose name differs from their parser
            -- (e.g, `typescriptreact` → `tsx`)
            -- Auto-start now lives in lua/core/treesitter.lua instead
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
                'mermaid',
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

        -- :TSManagerUpdateAll — force-reinstall every installed parser
        vim.api.nvim_create_user_command('TSManagerUpdateAll', function()
            local installer = require('tree-sitter-manager.installer')
            local repos     = require('tree-sitter-manager.repos')
            local util      = require('tree-sitter-manager.util')
            local count     = 0
            for lang in pairs(repos) do
                if vim.uv.fs_stat(util.ppath(lang)) then
                    installer.install(lang)
                    count = count + 1
                end
            end
            vim.notify(('Updating %d parsers…'):format(count))
        end, { desc = 'Update all installed treesitter parsers' })

        -- ts_context_commentstring is kept as a dependency for the LuaSnip
        -- snippets helper at lua/snippets/utils/commentstring.lua, which
        -- calls calculate_commentstring() to pick the right comment markers
        -- for snippet expansion (e.g. the box-comment / TODO snippets).
        --
        -- We don't call setup() and we don't override vim.filetype.get_option:
        -- - Native `gc` already walks the language tree itself and reads
        --   parser-shipped `(#set! ... bo.commentstring ...)` capture
        --   metadata, so it's polyglot-aware out of the box (markdown code
        --   blocks → lua comments, .vue <script> → JS comments, etc.).
        -- - The one place upstream got wrong (`jsx_attribute = "// %s"`,
        --   which doesn't parse between JSX attributes) is fixed by an
        --   `; extends` query at after/queries/jsx/highlights.scm.

        require('treesitter-context').setup()

        -- Textobjects (af/if, ac/ic, aa/ia) and function motion keymaps
        -- (]f/[f/]F/[F) live in lua/plugins/mini-ai.lua now. mini.ai uses
        -- gen_spec.treesitter() to drive function/class/parameter selection
        -- and MiniAi.move_cursor with search_method='next'/'prev' for jumps.
        -- (]c/[c now navigate git conflicts via mini.bracketed; class *motions*
        -- were dropped, but the ac/ic class textobjects remain.)

        -- Filetype-to-parser mappings and the FileType autocmd that calls
        -- vim.treesitter.start() live in lua/core/treesitter.lua, not here.
        -- Loading them at init time (before lazy) avoids a catch-up loop
        -- for the buffer that triggers this plugin's lazy-load.
    end,
}
