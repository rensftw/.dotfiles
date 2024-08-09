local ls = require('luasnip')
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local calculate_comment_string = require('Comment.ft').calculate
local region = require('Comment.utils').get_region

-- Source: https://github.com/L3MON4D3/LuaSnip/wiki/Cool-Snippets#all---todo-commentsnvim-snippets

--- Get the comment string {beg,end} table
---@param ctype integer 1 for `line`-comment and 2 for `block`-comment
---@return table comment_strings {begcstring, endcstring}
local get_cstring = function(ctype)
    -- use the `Comments.nvim` API to fetch the comment string for the region (eq. '--%s' or '--[[%s]]' for `lua`)
    local cstring = calculate_comment_string { ctype = ctype, range = region() } or ''
    -- as we want only the strings themselves and not strings ready for using `format` we want to split the beginning and end
    local cstring_table = vim.split(cstring, '%s', { plain = true, trimempty = true })
    -- identify whether the comment-string is one or two parts and create a `{beg, end}` table for it
    if #cstring_table == 0 then
        return { '', '' } -- default
    end
    return #cstring_table == 1 and { cstring_table[1], '' } or { cstring_table[1], cstring_table[2] }
end

local function create_box(opts)
  local pl = opts.padding_length or 4
  local function pick_comment_start_and_end()
    -- because lua block comment is unlike other language's,
    --  so handle lua ctype
    local ctype =  2
    if vim.opt.ft:get() == 'lua' then
      ctype = 1
    end
    local cs = get_cstring(ctype)[1]
    local ce = get_cstring(ctype)[2]
    if ce == '' or ce == nil then
      ce = cs
    end
    return cs, ce
  end
  return {
    -- top line
    f(function (args)
      local cs, ce = pick_comment_start_and_end()
      return cs .. string.rep(string.sub(cs, #cs, #cs), string.len(args[1][1]) + 2 * pl ) .. ce
    end, { 1 }),
    t{"", ""},
    f(function()
      local cs = pick_comment_start_and_end()
      return cs .. string.rep(' ',  pl)
    end),
    i(1, 'box'),
    f(function()
      local cs, ce = pick_comment_start_and_end()
      return string.rep(' ',  pl) .. ce
    end),
    t{"", ""},
    -- bottom line
    f(function (args)
      local cs, ce = pick_comment_start_and_end()
      return cs .. string.rep(string.sub(ce, 1, 1), string.len(args[1][1]) + 2 * pl ) .. ce
    end, { 1 }),
  }
end

return {
  s({trig = 'box'}, create_box{ padding_length = 8 }),
  s({trig = 'bbox'}, create_box{ padding_length = 20 }),
}

