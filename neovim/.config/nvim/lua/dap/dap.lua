return {
    'mfussenegger/nvim-dap',
    lazy = true,
    dependencies = {
        'rcarriga/nvim-dap-ui',
        'theHamsta/nvim-dap-virtual-text',
        'nvim-telescope/telescope.nvim',
        'nvim-telescope/telescope-dap.nvim',
    },
    keys = {
        { mode = { 'n' }, '<leader>db', function() require('dap').toggle_breakpoint() end },
        { mode = { 'n' }, '<leader>du', function() require('dapui').toggle() end },
        { mode = { 'n' }, '<leader>dc', function() require('dap').continue() end },
        { mode = { 'n' }, '<leader>do', function() require('dap').step_over() end },
        { mode = { 'n' }, '<leader>di', function() require('dap').step_into() end },
        { mode = { 'n' }, '<leader>dO', function() require('dap').step_out() end },
        { mode = { 'n' }, '<leader>dq', function() require('dap').terminate({ terminateDebugee = true }) end },

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
        'DapLoadLaunchJSON',
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
        vim.fn.sign_define('DapBreakpoint',          { text = '●', texthl = 'DapBreakpoint',          linehl = '', numhl = '' })
        vim.fn.sign_define('DapBreakpointCondition', { text = '●', texthl = 'DapBreakpointCondition', linehl = '', numhl = '' })
        vim.fn.sign_define('DapStopped',             { text = '󰝤', texthl = 'DapStopped',             linehl = '', numhl = '' })
        vim.fn.sign_define('DapLogPoint',            { text = '◆', texthl = 'DapLogPoint',            linehl = '', numhl = '' })

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
