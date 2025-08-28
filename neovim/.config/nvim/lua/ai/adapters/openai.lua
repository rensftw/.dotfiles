return function()
    return require('codecompanion.adapters').extend('openai', {
        name = 'openai',
        env = {
            api_key = 'cmd:pass show OPENAI_API_KEY',
        },
        schema = {
            model = {
                default = 'gpt-4o',
            },
        },
    })
end
