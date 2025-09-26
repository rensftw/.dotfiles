return function()
    return require('codecompanion.adapters').extend('gemini_cli', {
        name = 'Gemini CLI',
        defaults = {
            auth_method = 'gemini-api-key'
        },
        env = {
            GEMINI_API_KEY = "cmd: pass show GEMINI_API_KEY"
        },
        schema = {
            model = {
                default = 'gemini-2.5-pro',
            },
        },
    })
end
