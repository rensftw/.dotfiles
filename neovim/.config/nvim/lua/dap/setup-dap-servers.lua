require('dap-vscode-js').setup({
    adapters = {
        'pwa-node',
        'pwa-chrome',
        -- 'pwa-msedge',       --untested
        -- 'node-terminal',    -- untested
        -- 'pwa-extensionHost',--untested
    },
})

for _, language in ipairs({ 'typescript', 'javascript' }) do
    -- Example custom DAP configurations for JS:
    -- https://github.com/microsoft/vscode-js-debug/blob/main/OPTIONS.md
    require('dap').configurations[language] = {
        {
            type = 'pwa-node',
            request = 'launch',
            name = 'Launch file',
            program = '${file}',
            env = {
                NODE_OPTIONS = '--inspect',
            },
            profileStartup = false, --if true, will start profiling as soon as the process launches
            cwd = '${workspaceFolder}',
        },
        {
            type = 'pwa-node',
            request = 'attach',
            name = 'Attach to process',
            processId = require 'dap.utils'.pick_process,
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
