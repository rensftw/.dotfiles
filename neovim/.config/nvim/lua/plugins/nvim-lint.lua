return {
    'mfussenegger/nvim-lint',
    event = { 'BufReadPost', 'BufNewFile', 'BufWritePost' },
    config = function()
        local lint = require('lint')

        lint.linters_by_ft = {
            sh   = { 'shellcheck' },
            bash = { 'shellcheck' },
            -- markdown = { 'vale' },  -- enable when ready for prose linting
            -- NB: actionlint is deliberately NOT mapped to `yaml` — resolved by
            -- filetype it would run on every YAML buffer (docker-compose, k8s,
            -- pre-commit, etc and emit spurious "missing on/jobs" errors. It is
            -- invoked by path below, only for GitHub Actions workflow files.
        }

        local grp = vim.api.nvim_create_augroup('nvim-lint', { clear = true })
        vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
            group = grp,
            callback = function()
                lint.try_lint()  -- filetype-mapped linters (shellcheck, …)

                -- actionlint can't be selected by filetype (all `yaml`), so
                -- scope it to GitHub Actions workflow files by path.
                local path = vim.api.nvim_buf_get_name(0)
                if path:match('/%.github/workflows/.*%.ya?ml$') then
                    lint.try_lint('actionlint')
                end
            end,
        })
    end,
}
