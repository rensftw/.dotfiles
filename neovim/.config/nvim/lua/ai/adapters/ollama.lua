return function()
    return require('codecompanion.adapters').extend('ollama', {
        name = 'ollama',
        schema = {
            model = {
                default = 'qwen2.5-coder:7b',
            },
        },
    })
end
