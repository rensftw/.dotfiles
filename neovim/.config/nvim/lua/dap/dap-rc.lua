local dap = require('dap')
local dapui = require('dapui')

-- Customize breakpoint icons
vim.fn.sign_define('DapBreakpoint', { text = '🟦', texthl = '', linehl = '', numhl = '' })
vim.fn.sign_define('DapBreakpointCondition', { text = '🟪', texthl = '', linehl = '', numhl = '' })
vim.fn.sign_define('DapStopped', { text = '🟩', texthl = '', linehl = '', numhl = '' })
vim.fn.sign_define('DapLogPoint', { text = '💬', texthl = '', linehl = '', numhl = '' })

-- Automatically open DAP UI
dap.listeners.after.event_initialized['dapui_config'] = function()
    dapui.open()
end
dap.listeners.before.event_terminated['dapui_config'] = function()
    dapui.close()
end
dap.listeners.before.event_exited['dapui_config'] = function()
    dapui.close()
end

require('dap.setup-dap-servers')
require('dap.dap-ui-rc')