local ls = require('luasnip')
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local get_cstring = require('snippets.utils.commentstring').get_cstring

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

