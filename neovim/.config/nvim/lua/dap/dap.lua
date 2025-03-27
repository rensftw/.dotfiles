return {
    'mfussenegger/nvim-dap',
    lazy = true,
    dependencies = {
        'rcarriga/nvim-dap-ui',
        'theHamsta/nvim-dap-virtual-text',
        'nvim-telescope/telescope.nvim',
        'nvim-telescope/telescope-dap.nvim',
        'nvim-neotest/nvim-nio',
    },
    keys = {
        { mode = { 'n' }, '<leader>db', function() require('dap').toggle_breakpoint() end },
        { mode = { 'n' }, '<leader>dB', function() require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: ')) end },
        { mode = { 'n' }, '<leader>du', function() require('dapui').toggle() end },
        { mode = { 'n' }, '<leader>dc', function() require('dap').continue() end },
        { mode = { 'n' }, '<leader>do', function() require('dap').step_over() end }, -- Step over the current line
        { mode = { 'n' }, '<leader>di', function() require('dap').step_into() end }, -- Step into the current expression
        { mode = { 'n' }, '<leader>dO', function() require('dap').step_out() end },  -- Step out of the current scope
        { mode = { 'n' }, '<leader>dq', function() require('dap').terminate({ terminateDebugee = true }) end },
        { mode = { 'n' }, '<leader>de', function() require('dapui').eval(nil, { enter = true }) end },

        -- DAP terminal navigation
        { mode = { 't' }, '<C-h>', '<C-\\><C-n><C-w>h' },
        { mode = { 't' }, '<C-j>', '<C-\\><C-n><C-w>j' },
        { mode = { 't' }, '<C-k>', '<C-\\><C-n><C-w>k' },
        { mode = { 't' }, '<C-l>', '<C-\\><C-n><C-w>l' },

        -- DAP + Telescope integration
        { mode = { 'n' }, '<leader>ds', function() require('telescope').extensions.dap.frames({initial_mode = 'normal' }) end }
    },
    cmd = {
        'DapShowLog',
        'DapSetLogLevel',
        'DapToggleBreakpoint',
        'DapContinue',
        'DapStepInto',
        'DapStepOut',
        'DapStepOver',
        'DapTerminate',
        'DapToggleRepl',
    },
    config = function()
        local dap = require('dap')
        local dapui = require('dapui')

        -- Highlight stopped line
        vim.api.nvim_set_hl(0, 'DapStoppedLine', { default = true, link = "Visual" })

        -- Customize breakpoint icons
        vim.api.nvim_set_hl(0, 'DapStoppedDebuggerLine', {bg = '#1c3c72', bold = 50})
        vim.api.nvim_set_hl(0, 'DapStoppedSymbol', {fg = '#3072e0', bold = 50})
        vim.fn.sign_define('DapBreakpoint',          { text = '●', texthl = 'ErrorMsg',          linehl = '', numhl = '' })
        vim.fn.sign_define('DapBreakpointCondition', { text = '⁇', texthl = 'Conditional',       linehl = '', numhl = '' })
        vim.fn.sign_define('DapStopped',             { text = '󰝤', texthl = 'DapStoppedSymbol',    linehl = 'DapStoppedDebuggerLine', numhl = '' })
        vim.fn.sign_define('DapLogPoint',            { text = '◆', texthl = 'DapLogPoint',       linehl = '', numhl = '' })

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

        require('dap.utils.setup-dap-servers')
        require('telescope').load_extension('dap')
    end
}
