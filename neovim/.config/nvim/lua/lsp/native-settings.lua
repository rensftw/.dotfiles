-- Define diagnostic signs
vim.fn.sign_define(
  'DiagnosticSignError',
  { texthl = 'DiagnosticSignError', text = '' }
)

vim.fn.sign_define(
  'DiagnosticSignWarn',
  { texthl = 'DiagnosticSignWarn', text = '' }
)

vim.fn.sign_define(
  'DiagnosticSignHint',
  -- { texthl = 'DiagnosticSignHint', text = '' }
  { texthl = 'DiagnosticSignHint', text = '' }
)

vim.fn.sign_define(
  'DiagnosticSignInfo',
  { texthl = 'DiagnosticSignInfo', text = '' }
)
