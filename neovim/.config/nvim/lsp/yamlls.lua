return {
    settings = {
        yaml = {
            schemaStore = {
                enable = true,
                -- Avoid "TypeError: Cannot read properties of undefined (reading 'length')"
                url    = '',
            },
            schemas = require('schemastore').yaml.schemas(),
        },
    },
}
