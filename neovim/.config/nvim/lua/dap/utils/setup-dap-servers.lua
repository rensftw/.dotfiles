local dap = require('dap')

dap.adapters['pwa-node'] = {
    type = 'server',
    host = 'localhost',
    port = '${port}',
    executable = {
        -- Because of mason we can use this command
        command = 'js-debug-adapter',
        args = { '${port}' },
    }
}

-- dap.adapters['node-terminal'] = {
--     type = 'executable',
--     command = 'js-debug-adapter',
-- }

dap.adapters['node-terminal'] = {
    type = 'server',
    host = 'localhost',
    port = '${port}',
    executable = {
        -- Because of mason we can use this command
        command = 'js-debug-adapter',
        args = { '${port}' },
    }
}

for _, language in ipairs({ 'typescript', 'javascript' }) do
    -- Example custom DAP configurations for JS:
    -- https://github.com/microsoft/vscode-js-debug/blob/main/OPTIONS.md
    dap.configurations[language] = {
        {
            type = 'pwa-node',
            request = 'launch',
            name = 'Launch file',
            program = '${file}',
            cwd = '${workspaceFolder}',
        },
        {
            type = 'pwa-node',
            request = 'attach',
            name = 'Attach to process',
            processId = require('dap.utils').pick_process,
            cwd = '${workspaceFolder}',
        },
        {
            type = 'node-terminal',
            request = 'launch',
            name = 'Launch debug terminal',
            cwd = '${workspaceFolder}',
        },
        {
            type = 'pwa-node',
            request = 'launch',
            name = 'Debug build script',
            -- trace = true, -- include debugger info
            runtimeExecutable = 'yarn',
            runtimeArgs = { 'build' },
            env = {
                NODE_OPTIONS = '--inspect',
            },
            rootPath = '${workspaceFolder}',
            cwd = '${workspaceFolder}',
            console = 'integratedTerminal',
            internalConsoleOptions = 'neverOpen',
        },
        {
            type = 'pwa-node',
            request = 'launch',
            name = 'Debug Jest tests',
            -- trace = true, -- include debugger info
            runtimeExecutable = 'node',
            runtimeArgs = {
                './node_modules/jest/bin/jest.js',
                '--runInBand',
            },
            rootPath = '${workspaceFolder}',
            cwd = '${workspaceFolder}',
            console = 'integratedTerminal',
            internalConsoleOptions = 'neverOpen',
        }
    }
end
