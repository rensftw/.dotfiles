return {
    'mfussenegger/nvim-lint',
    event = { 'BufReadPost', 'BufNewFile', 'BufWritePost' },
    config = function()
        local lint = require('lint')

        lint.linters_by_ft = {
            yaml = { 'actionlint' },  -- fires on .github/workflows/*.yml
            sh   = { 'shellcheck' },
            bash = { 'shellcheck' },
            -- markdown = { 'vale' },  -- enable when ready for prose linting
        }

        local grp = vim.api.nvim_create_augroup('nvim-lint', { clear = true })
        vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
            group = grp,
            callback = function() lint.try_lint() end,
        })
    end,
}
