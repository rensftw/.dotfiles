return {
    'epwalsh/obsidian.nvim',
    version = '*', -- recommended, use latest release instead of latest commit
    lazy = true,
    event = {
        -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
        'BufReadPre ' .. vim.fn.expand('$OBSIDIAN_LOCATION') .. '/**.md',
        'BufNewFile ' .. vim.fn.expand('$OBSIDIAN_LOCATION') .. '/**.md',
    },
    cmd = {
        'ObsidianOpen',
        'ObsidianNew',
        'ObsidianQuickSwitch',
        'ObsidianFollowLink',
        'ObsidianBacklinks',
        'ObsidianToday',
        'ObsidianTomorrow',
        'ObsidianYesterday',
        'ObsidianTemplate',
        'ObsidianSearch',
        'ObsidianRename',
    },
    dependencies = {
        'nvim-lua/plenary.nvim',
        'hrsh7th/nvim-cmp',
        'nvim-telescope/telescope.nvim',
    },
    config = function()
        -- Set conceallevel to 1 so checkboxes can be pretty printed
        vim.wo.conceallevel = 1

        require('obsidian').setup({
            workspaces = {
                {
                    name = 'personal',
                    path = vim.fn.expand('$OBSIDIAN_LOCATION')
                }
            },
            mappings = {
                -- Overrides the 'gf' mapping to work on markdown/wiki links within your vault.
                ['gf'] = {
                    action = function()
                        return require('obsidian').util.gf_passthrough()
                    end,
                    opts = { noremap = false, expr = true, buffer = true },
                },
                -- Toggle check-boxes.
                ['<leader>x'] = {
                    action = function()
                        return require('obsidian').util.toggle_checkbox()
                    end,
                    opts = { buffer = true },
                },
            },
            completion = {
                -- Set to false to disable completion.
                nvim_cmp = true,

                -- Where to put new notes created from completion. Valid options are
                --  * 'current_dir' - put new notes in same directory as the current buffer.
                --  * 'notes_subdir' - put new notes in the default notes subdirectory.
                new_notes_location = 'current_dir',

                -- Control how wiki links are completed with these (mutually exclusive) options:
                --
                -- 1. Whether to add the note ID during completion.
                -- E.g. '[[Foo' completes to '[[foo|Foo]]' assuming 'foo' is the ID of the note.
                -- Mutually exclusive with 'prepend_note_path' and 'use_path_only'.
                prepend_note_id = true,
                -- 2. Whether to add the note path during completion.
                -- E.g. '[[Foo' completes to '[[notes/foo|Foo]]' assuming 'notes/foo.md' is the path of the note.
                -- Mutually exclusive with 'prepend_note_id' and 'use_path_only'.
                prepend_note_path = false,
                -- 3. Whether to only use paths during completion.
                -- E.g. '[[Foo' completes to '[[notes/foo]]' assuming 'notes/foo.md' is the path of the note.
                -- Mutually exclusive with 'prepend_note_id' and 'prepend_note_path'.
                use_path_only = false,
            },
            templates = {
                subdir = 'config/templates',
                date_format = '%Y-%m-%d',
                time_format = '%H:%M',
                -- A map for custom variables, the key should be the variable and the value a function
                substitutions = {},
            },
            note_id_func = function(title)
                local suffix = ''
                if title ~= nil then
                    -- If title is given, transform it into valid file name.
                    return tostring(title)
                else
                    -- If title is nil, just add 4 random uppercase letters to the suffix.
                    for _ = 1, 4 do
                        suffix = suffix .. string.char(math.random(65, 90))
                    end
                    return tostring(os.time()) .. '-' .. suffix
                end
            end,
            daily_notes = {
                folder = 'daily-log',
                date_format = '%Y-%m-%d',
                -- Optional, if you want to automatically insert a template from your template directory like 'daily.md'
                template = 'daily-log-entry.md'
            },
        })
    end
}
