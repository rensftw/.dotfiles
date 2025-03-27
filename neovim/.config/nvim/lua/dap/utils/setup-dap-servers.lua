local dap = require('dap')

local dapDebugServer = require('mason-registry').get_package('js-debug-adapter'):get_install_path() .. '/js-debug/src/dapDebugServer.js'

dap.adapters['pwa-node'] = {
    type = 'server',
    host = 'localhost',
    port = '${port}',
    executable = {
        command = 'node',
        args = { dapDebugServer, '${port}' },
    }
}

dap.adapters['node-terminal'] = {
    type = 'server',
    host = 'localhost',
    port = '${port}',
    executable = {
        command = 'node',
        args = { dapDebugServer, '${port}' },
    }
}

for _, language in ipairs({ 'typescript', 'javascript' }) do
    -- Example custom DAP configurations for JS:
    -- https://code.visualstudio.com/docs/nodejs/nodejs-debugging
    -- https://github.com/microsoft/vscode-js-debug/blob/main/OPTIONS.md
    dap.configurations[language] = {
        {
            type = 'pwa-node',
            request = 'launch',
            name = 'Launch file',
            program = '${file}',
            cwd = '${workspaceFolder}',
            console = 'integratedTerminal',
        },
        {
            type = 'pwa-node',
            request = 'attach',
            name = 'Attach to process',
            processId = require('dap.utils').pick_process,
            cwd = '${workspaceFolder}',
            console = 'integratedTerminal',
        },
        {
            type = 'node-terminal',
            request = 'launch',
            name = 'Launch debug terminal',
            cwd = '${workspaceFolder}',
            console = 'integratedTerminal',
            autoAttachChildProcesses = true,
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
