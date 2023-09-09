return {
    'folke/noice.nvim',
    enabled = false,
    event = 'VeryLazy',
    dependencies = {
        'MunifTanjim/nui.nvim',
        -- OPTIONAL:
        --   `nvim-notify` is only needed, if you want to use the notification view.
        --   If not available, we use `mini` as the fallback
        'rcarriga/nvim-notify',
    },
    config = function()
        require('noice').setup({
            cmdline = {
                enabled = true,
                view = 'cmdline',
            },
            messages = {
                enabled = true,
            },
            popupmenu = {
                enabled = false,
            },
            notify = {
                enabled = true,
            },
            lsp = {
                progress = {
                    enabled = true,
                    -- Lsp Progress is formatted using the builtins for lsp_progress. See config.format.builtin
                    -- See the section on formatting for more details on how to customize.
                    --- @type NoiceFormat|string
                    format = 'lsp_progress',
                    --- @type NoiceFormat|string
                    format_done = 'lsp_progress_done',
                    throttle = 1000 / 30, -- frequency to update lsp progress message
                    view = 'mini',
                },
                override = {
                    -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
                    ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
                    ['vim.lsp.util.stylize_markdown'] = true,
                    ['cmp.entry.get_documentation'] = true,
                },
                hover = {
                    enabled = true,
                    silent = true, -- set to true to not show a message if hover is not available
                    view = nil,    -- when nil, use defaults from documentation
                    ---@type NoiceViewOptions
                    opts = {},     -- merged with defaults from documentation
                },
                signature = {
                    enabled = true,
                    auto_open = {
                        enabled = true,
                        trigger = true, -- Automatically show signature help when typing a trigger character from the LSP
                        luasnip = true, -- Will open signature help when jumping to Luasnip insert nodes
                        throttle = 50,  -- Debounce lsp signature help request by 50ms
                    },
                    view = nil,         -- when nil, use defaults from documentation
                    ---@type NoiceViewOptions
                    opts = {},          -- merged with defaults from documentation
                },
                message = {
                    -- Messages shown by lsp servers
                    enabled = true,
                    view = 'notify',
                    opts = {},
                },
                -- defaults for hover and signature help
                documentation = {
                    view = 'hover',
                    ---@type NoiceViewOptions
                    opts = {
                        lang = 'markdown',
                        replace = true,
                        render = 'plain',
                        format = { '{message}' },
                        win_options = { concealcursor = 'n', conceallevel = 3 },
                    },
                },
            },
            markdown = {
                hover = {
                    ['|(%S-)|'] = vim.cmd.help,                       -- vim help links
                    ['%[.-%]%((%S-)%)'] = require('noice.util').open, -- markdown links
                },
                highlights = {
                    ['|%S-|'] = '@text.reference',
                    ['@%S+'] = '@parameter',
                    ['^%s*(Parameters:)'] = '@text.title',
                    ['^%s*(Return:)'] = '@text.title',
                    ['^%s*(See also:)'] = '@text.title',
                    ['{%S-}'] = '@parameter',
                },
            },
            health = {
                checker = true, -- Disable if you don't want health checks to run
            },
            smart_move = {
                -- noice tries to move out of the way of existing floating windows.
                enabled = true, -- you can disable this behaviour here
                -- add any filetypes here, that shouldn't trigger smart move.
                excluded_filetypes = { 'cmp_menu', 'cmp_docs', 'notify' },
            },
            ---@type NoicePresets
            presets = {
                -- you can enable a preset by setting it to true, or a table that will override the preset config
                -- you can also add custom presets that you can enable/disable with enabled=true
                bottom_search = true,         -- use a classic bottom cmdline for search
                command_palette = true,       -- position the cmdline and popupmenu together
                long_message_to_split = true, -- long messages will be sent to a split
                inc_rename = false,           -- enables an input dialog for inc-rename.nvim
                lsp_doc_border = true,        -- add a border to hover docs and signature help
            },
            throttle = 1000 / 30,             -- how frequently does Noice need to check for ui updates? This has no effect when in blocking mode.
            routes = {
                {
                    filter = {
                        event = 'msg_show',
                        kind = '',
                    },
                    opts = { skip = true },
                },
            }
        })
    end
}
