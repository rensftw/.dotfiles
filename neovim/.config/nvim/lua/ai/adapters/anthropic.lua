return function()
    return require('codecompanion.adapters').extend('anthropic', {
        name = 'anthropic',
        env = {
            api_key = 'cmd:pass show ANTHROPIC_API_KEY',
        },
        schema = {
            model = {
                default = 'claude-sonnet-4-20250514',
            },
        },
    })
end
