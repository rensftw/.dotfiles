local ls = require('luasnip')
local types = require('luasnip.util.types')
local javascript_snippets = require('snippets.javascript');
local html_snippets = require('snippets.html')
-- local work_snippets = require('snippets.work')

ls.config.set_config({
    -- This tells LuaSnip to remember to keep around the last snippet
    -- You can jump back into it even if you move outside of the selection
	history = true,
	-- Cool if you have dynamic snippets, it updates as you type
	update_events = "TextChanged,TextChangedI",
	-- Useful when `history` is enabled.
	delete_check_events = "TextChanged",
	ext_opts = {
		[types.choiceNode] = {
			active = {
                virt_text = { { " <- Current Choice", "NonTest" } },
			},
		},
	},
	-- treesitter-hl has 100, use something higher (default is 200).
	ext_base_prio = 300,
	-- minimal increase in priority.
	ext_prio_increase = 1,
	enable_autosnippets = true,
	-- mapping for cutting selected text so it's usable as SELECT_DEDENT,
	-- SELECT_RAW or TM_SELECTED_TEXT (mapped via xmap).
	store_selection_keys = "<Tab>",
})

ls.snippets = {
    javascript = javascript_snippets,
    html = html_snippets,
    -- markdown = work_snippets
}

vim.api.nvim_set_keymap('i', '<C-s>', '<Plug>luasnip-next-choice', {})
vim.api.nvim_set_keymap('s', '<C-s>', '<Plug>luasnip-next-choice', {})
