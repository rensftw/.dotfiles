-- Write all changes to modified buffers,
-- close all buffers except the active one,
-- and return focus to the same spot it was initially
vim.api.nvim_create_user_command('BufOnly', 'wa | %bdelete | edit # | bdelete # | normal `"', {})

-- Apply macro recorded in @a register to quickfix list items
-- exclamation mark in `norm!` is to ensure no custom mappings of abbreviations interfere
vim.api.nvim_create_user_command('ApplyMacroToQuickfix', 'cdo execute "norm! @a" | update', {})

-- Create a ASCII box art over a visually selected range.
-- By default it uses `headline` and will look like this:
-- /*****************************/
-- /*  H e l l o   w o r l d !  */
-- /*****************************/
--
-- Run `boxes --list` to view all available styles
vim.api.nvim_create_user_command('AsciiBoxart', function(opts)
  -- Get the range of visually selected lines
  local line1 = opts.line1
  local line2 = opts.line2
  -- Get the design option from the argument, default to "headline" if not provided
  local design = opts.args ~= "" and opts.args or "headline"

  local cmd = string.format(":%d,%d!boxes --no-color --size=80 --align=c --design %s", line1, line2, design)
  vim.cmd(cmd)
end, { range = true, nargs = '?' })
