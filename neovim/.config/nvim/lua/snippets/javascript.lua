local ls = require('luasnip')
local rep = require("luasnip.extras").rep
local fmt = require('luasnip.extras.fmt').fmt
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node

local function print_random_emoji()
    local emoji = {
        '🦄', '🚧', '📚', '🍯', '📮', '🐌', '🧵', '🧩',
        '🤖', '🎙', '🍔', '💖', '🪖', '👑', '⚙️', '🧤',
        '🚨', '🚗', '🎃', '💄', '👾', '🧠', '🦷', '🐲',
        '👒', '🌞', '🌈', '🐝', '🐡', '🌳', '🍇','🍓',
        '🥨', '🧀', '🍥', '🏀', '🏓', '🥊', '🎸', '🎯',
    }

    math.randomseed(os.time())
    local random_emoji = emoji[math.random(1, 40)]
    print(vim.inspect(random_emoji))
    return random_emoji
end

local function get_time()
    return os.date "%D - %H:%M"
end

local console_log = s(
    'cl',
    fmt([[console.log('{}  {}', {});]], {
        f(print_random_emoji),
        i(1),
        c(2, {i(3), rep(1)}),
    })
)

local time = s('time', f(get_time))

-- Make this a choice node
local todo = s('todo', { t('// TODO(irena.angelova):') })

local snippets = {
    console_log,
    todo,
    time
}

return snippets
