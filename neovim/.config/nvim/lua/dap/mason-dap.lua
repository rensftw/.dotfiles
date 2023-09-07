return {
    'jay-babu/mason-nvim-dap.nvim',
    dependencies = {
        'williamboman/mason.nvim',
    },
    cmd = { 'DapInstall', 'DapUninstall' },
    lazy = true,
    config = function()
        require('mason-nvim-dap').setup({
            -- Makes a best effort to setup the various debuggers with
            -- reasonable debug configurations
            automatic_installation = true,
            ensure_installed = { 'js' },
        });
    end
}
