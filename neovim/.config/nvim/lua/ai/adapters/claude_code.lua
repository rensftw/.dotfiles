return function()
    return require('codecompanion.adapters').extend('claude_code', {
        name = 'Claude Code',
        env = {
            ANTHROPIC_API_KEY = "cmd: pass show ANTHROPIC_API_KEY"
        },
        schema = {
            model = {
                default = 'claude-sonnet-4',
            },
        },
    })
end
