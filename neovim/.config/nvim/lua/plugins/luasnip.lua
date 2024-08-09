return {
    'L3MON4D3/LuaSnip',
    lazy = true,
    config = function()
        local ls = require('luasnip')
        local types = require('luasnip.util.types')
        local javascript_snippets = require('snippets.javascript');
        local html_snippets = require('snippets.html')
        local comment_snippets = require('snippets.comments')
        local box_comment = require('snippets.box-comment')
        -- local work_snippets = require('snippets.work')

        ls.config.set_config({
            -- This tells LuaSnip to remember to keep around the last snippet
            -- You can jump back into it even if you move outside of the selection
            history = true,
            -- Cool if you have dynamic snippets, it updates as you type
            update_events = 'TextChanged,TextChangedI',
            -- Useful when `history` is enabled.
            delete_check_events = 'TextChanged',
            ext_opts = {
                [types.choiceNode] = {
                    active = {
                        virt_text = { { ' <- Current Choice', 'NonTest' } },
                    },
                },
            },
            -- treesitter-hl has 100, use something higher (default is 200).
            ext_base_prio = 300,
            -- minimal increase in priority.
            ext_prio_increase = 1,
            enable_autosnippets = true,
        })

        ls.add_snippets('all', comment_snippets)
        ls.add_snippets('all', box_comment)
        ls.add_snippets('javascript', javascript_snippets)
        ls.add_snippets('typescript', javascript_snippets)
        ls.add_snippets('typescriptreact', javascript_snippets)
        ls.add_snippets('vue', javascript_snippets)
        ls.add_snippets('html', html_snippets)
        -- ls.add_snippets('markdown', work_snippets)

        vim.keymap.set({'i', 's'}, '<C-s>', function()
            if ls.choice_active() then
                ls.change_choice(1)
            end
        end, {silent = true, noremap = true})
    end
}
