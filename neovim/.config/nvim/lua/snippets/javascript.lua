local ls = require('luasnip')
local rep = require('luasnip.extras').rep
local fmt = require('luasnip.extras.fmt').fmt
local s = ls.snippet
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node

local function print_random_emoji()
    local emoji = {
        '๐ฆ', '๐ง', '๐', '๐ฏ', '๐ฎ', '๐', '๐งต', '๐งฉ',
        '๐ค', '๐ฅ', '๐', '๐', '๐', '๐', '๐ฅ', '๐งค',
        '๐จ', '๐', '๐', '๐', '๐พ', '๐ง ', '๐ฆท', '๐ฒ',
        '๐', '๐', '๐', '๐', '๐ก', '๐ณ', '๐', '๐',
        '๐ฅจ', '๐ง', '๐ฅ', '๐', '๐', '๐ฅ', '๐ธ', '๐ฏ',
    }

    math.randomseed(os.time())
    return emoji[math.random(1, 40)]
end

local console_log = s(
    'cl',
    fmt([[console.log('{}  {}', {});]], {
        f(print_random_emoji),
        i(1),
        c(2, { i(3), rep(1) }),
    })
)

local snippets = {
    console_log,
}

return snippets
