local M = {}

--- Return the comment markers for the current cursor location as a
--- { begin, end } table.
---
--- Routes through `ts_context_commentstring` so that, in polyglot files
--- (TSX, Vue, Svelte, …), the right markers are returned based on the
--- region under the cursor — e.g. `{/* */}` inside JSX vs `// ` inside JS.
---
--- For languages with no `__multiline` definition, ctype=2 transparently
--- falls back to the line variant (tcc handles that internally).
---
--- Source pattern: https://github.com/L3MON4D3/LuaSnip/wiki/Cool-Snippets#all---todo-commentsnvim-snippets
---
---@param ctype integer 1 for line-comment, 2 for block-comment
---@return table comment_strings { begcstring, endcstring }
function M.get_cstring(ctype)
    local key = ctype == 2 and '__multiline' or '__default'
    local cstring = require('ts_context_commentstring.internal').calculate_commentstring({ key = key }) or ''

    -- Split the format-ready commentstring (e.g. `-- %s` or `<!-- %s -->`)
    -- into its begin and end markers. Native commentstrings often include
    -- whitespace around `%s` (lua: `"-- %s"`, html: `"<!-- %s -->"`); trim
    -- it off each marker so callers (e.g. the box-comment snippet that
    -- inspects the last char of the marker) don't end up reading a space.
    local cstring_table = vim.split(cstring, '%s', { plain = true, trimempty = true })
    for idx, marker in ipairs(cstring_table) do
        cstring_table[idx] = vim.trim(marker)
    end

    if #cstring_table == 0 then
        return { '', '' }
    end

    -- One-part commentstrings (e.g. lua's `-- %s`) get a trailing empty string.
    return #cstring_table == 1
        and { cstring_table[1], '' }
        or  { cstring_table[1], cstring_table[2] }
end

return M
