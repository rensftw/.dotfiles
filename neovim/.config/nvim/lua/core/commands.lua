-- Write all changes to modified buffers,
-- close all buffers except the active one,
-- and return focus to the same spot it was initially
vim.api.nvim_create_user_command('BufOnly', 'wa | %bdelete | edit # | bdelete # | normal `"', {})

-- Create a ASCII box art over a visually selected range.
-- By default it uses `headline` and will look like this:
-- /*****************************/
-- /*  H e l l o   w o r l d !  */
-- /*****************************/
--
-- Run `boxes --list` to view all available styles
vim.api.nvim_create_user_command('Boxart', function(opts)
  -- Get the range of visually selected lines
  local line1 = opts.line1
  local line2 = opts.line2
  -- Get the design option from the argument, default to "headline" if not provided
  local design = opts.args ~= "" and opts.args or "headline"

  local cmd = string.format(":%d,%d!boxes --no-color --size=80 --align=c --design %s", line1, line2, design)
  vim.cmd(cmd)
end, { range = true, nargs = '?' })

-- Apply macro recorded in register to quickfix list items
-- Usage assuming we recorded in register q:
-- :QuickfixListApplyMacro q
vim.api.nvim_create_user_command('QuickfixListApplyMacro', function (opts)
    local register = opts.args

    -- exclamation mark in `norm!` is to ensure no custom mappings of abbreviations interfere
    local cmd = string.format('cdo execute "norm! @%s" | update', register)
    vim.cmd(cmd)
end, { nargs = 1 })

-- Filter QF list entries based on allowlist file containing filepaths
-- Usage:
-- :QuickfixListFilter path/to/allowlist.txt
vim.api.nvim_create_user_command('QuickfixListFilter', function(opts)
    local allowlist_path = opts.args
    local allowlist = {}
    if not allowlist_path then
        vim.notify('Please provide the path to the allowlist file.', vim.log.levels.ERROR)
        return
    end

    -- Open the allowlist.txt file for reading
    local file, err = io.open(allowlist_path, "r")
    if not file then
        error('Failed to open allowlist file: ' .. err)
    end

    -- Read each line from the file and add it to the allowlist
    for line in file:lines() do
        table.insert(allowlist, line)
    end

    -- Close the file
    file:close()

    local qflist = vim.fn.getqflist({ items = {} })
    local filtered_qflist = {}

    for _, entry in ipairs(qflist.items) do
        for _, allowed in ipairs(allowlist) do
          -- Escape special characters (such as / and .) in allowed string
          local escaped_allowed = allowed:gsub("%W", "%%%1")
          local filename = vim.api.nvim_buf_get_name(entry.bufnr)

            if filename:find(escaped_allowed) ~= nil then
                table.insert(filtered_qflist, entry)
            end
        end
    end

    vim.fn.setqflist({}, 'a')
    vim.fn.setqflist(filtered_qflist)
end, { nargs = 1 })

-- Deduplicate entries in quickfix list so that there is one entry per filepath
vim.api.nvim_create_user_command('QuickfixListDeduplicate', function()
    local qflist = vim.fn.getqflist({ items = {} })
    local deduped_qflist = {}

    for _, item in ipairs(qflist.items) do
        local found = false
        local filename = vim.api.nvim_buf_get_name(item.bufnr)

        for _, dedup_item in ipairs(deduped_qflist) do
            if dedup_item.filename == filename then
                found = true
                break
            end
        end

        if not found then
            table.insert(deduped_qflist, { filename = filename })
        end
    end

    vim.fn.setqflist({}, 'a')
    vim.fn.setqflist(deduped_qflist)
end, {})
