return {
    'ibhagwan/fzf-lua',
    lazy = true,
    cmd = { 'FzfLua' },
    keys = {
        { mode = { 'n' }, '<leader>o',  function() require('fzf-lua').files({ previewer = false }) end,                                         desc = 'Find files' },
        { mode = { 'n' }, '<leader>i',  function() require('fzf-lua').resume() end,                                                              desc = 'Resume last picker' },
        { mode = { 'n' }, '<leader>.',  function() require('fzf-lua').files({ cwd = vim.fn.expand('$HOME/.dotfiles'), cwd_prompt = true }) end, desc = 'Find dotfiles' },
        { mode = { 'n' }, '<leader>fb', function() require('fzf-lua').blines() end,                                                              desc = 'Buffer fuzzy find' },
        { mode = { 'n' }, '<leader>ff', function() require('fzf-lua').live_grep() end,                                                           desc = 'Live grep' },
        {
            mode = { 'n' },
            '<leader>fa',
            function() require('fzf-lua').grep({ search = vim.fn.input('   filter grep ❯ ') }) end,
            desc = 'Grep with input',
        },
        -- Prefer to expand <cword> because fzf.grep_cword inserts `\bhello\b`
        { mode = { 'n' }, '<leader>fw', function() require('fzf-lua').grep({ search = vim.fn.expand('<cword>')}) end, desc = 'Grep word under cursor' },
        { mode = { 'v' }, '<leader>fv', function() require('fzf-lua').grep_visual() end, desc = 'Grep visual selection' },
        { mode = { 'n' }, '<leader>b',  function() require('fzf-lua').buffers() end,    desc = 'Buffers' },
        { mode = { 'n' }, '<leader>t',  function() require('fzf-lua').tabs() end,       desc = 'Tabs' },
        { mode = { 'n' }, '<leader>?',  function() require('fzf-lua').helptags() end,   desc = 'Help tags' },
        { mode = { 'n' }, '<leader>m',  function() require('fzf-lua').manpages() end,   desc = 'Man pages' },
        { mode = { 'n' }, '<leader>:',  function() require('fzf-lua').commands() end,   desc = 'Commands' },
        { mode = { 'n' }, '<leader>gs', function() require('fzf-lua').git_status() end, desc = 'Git status' },
        {
            mode = { 'n' },
            '<leader>gcbb',
            function() require('fzf-lua').git_branches({ cmd = 'git branch --color' }) end,
            desc = 'Git branches (local only)',
        },
    },
    config = function()
        local fzf     = require('fzf-lua')
        local actions = fzf.actions

        -- Center the cursor (zz) after a file-open action so the jumped-to
        -- line lands in the middle of the viewport.
        local function with_zz(action)
            return function(selected, opts)
                action(selected, opts)
                vim.cmd('normal! zz')
            end
        end

        -- Ctrl-Q action: if the user has Tab-marked one or more entries, send
        -- only those to the quickfix list. If nothing is multi-selected, send
        -- ALL currently visible matches.
        --
        -- The trick is the `transform` fzf bind, which runs the shell snippet
        -- before the accept fires. fzf exposes the multi-select count via
        -- $FZF_SELECT_COUNT; when it's 0 we emit `select-all` (an fzf action
        -- that fzf will execute), causing every visible match to be selected
        -- before the accept runs. When it's >0 the snippet emits nothing, so
        -- only the user's marked entries are accepted.
        local ctrl_q_to_qf = {
            prefix = 'transform([ "${FZF_SELECT_COUNT:-0}" -eq 0 ] && echo select-all)+',
            fn = function(selected, opts)
                actions.file_sel_to_qf(selected, opts)
                vim.cmd('copen')
            end,
            header = 'send to QF',
        }

        -- Ctrl-A: diff two Tab-marked entries side-by-side. Only fires when
        -- exactly 2 are selected; otherwise warns and bails. Uses fzf-lua's
        -- own entry parser so this works uniformly across the files, buffers,
        -- and git_status pickers (each embeds path info differently). Vim's
        -- builtin :diffsplit reuses an already-loaded buffer when the path
        -- matches, so picking 2 currently-open buffers Just Works.
        local ctrl_a_to_diff = {
            fn = function(selected, opts)
                if #selected ~= 2 then
                    vim.notify(
                        ('ctrl-a diff: select exactly 2 entries (got %d)'):format(#selected),
                        vim.log.levels.WARN
                    )
                    return
                end
                local path = require('fzf-lua.path')
                local p1 = path.entry_to_file(selected[1], opts).path
                local p2 = path.entry_to_file(selected[2], opts).path
                vim.cmd('edit ' .. vim.fn.fnameescape(p1))
                vim.cmd('vert diffsplit ' .. vim.fn.fnameescape(p2))
            end,
            header = 'diff selected pair',
        }

        fzf.setup({
            winopts = {
                row         = 2,
                col         = 0.5,
                width       = 0.85,
                height      = 0.85,
                -- Suppress single-letter mode badges in the title (e.g. the `h`
                -- flag that fzf-lua adds when files.cmd / grep.rg_opts include
                -- `--hidden`). Cosmetic; the toggles still work, the title
                -- just doesn't display them.
                title_flags = false,
                ---@diagnostic disable-next-line: missing-fields
                preview     = {
                    layout     = 'horizontal',
                    horizontal = 'right:50%',
                    scrollbar  = false,
                },
            },

            fzf_opts = {
                ['--prompt']         = '   ',
                ['--pointer']        = '❯',
                ['--header-border']  = 'bottom',
                ['--cycle']          = true, -- wrap j/k at list edges
                ['--highlight-line'] = true, -- highlight whole row of current selection
            },

            -- Navigation:
            --  - List:    Ctrl-J / Ctrl-K (line by line).
            --  - Preview: Ctrl-D / Ctrl-U for half-page (vim-parity). Alt-letter
            --             chords are unavailable here because Aerospace owns
            --             alt-{h,j,k,l} for window focus on this machine.
            --             Mirrors the FZF_DEFAULT_OPTS bind in zsh/.zshrc so
            --             muscle memory carries between vanilla terminal fzf
            --             and fzf-lua.
            --
            --  Both keymap tables are populated:
            --    - `keymap.fzf` covers fzf's *native* previewer (e.g. when
            --       using `bat` or another command-line previewer).
            --    - `keymap.builtin` covers fzf-lua's *builtin* previewer
            --       (a Neovim window, the default for most pickers).
            keymap = {
                fzf = {
                    ['ctrl-j'] = 'down',
                    ['ctrl-k'] = 'up',
                    ['ctrl-d'] = 'preview-half-page-down',
                    ['ctrl-u'] = 'preview-half-page-up',
                },
                builtin = {
                    ['<C-d>'] = 'preview-half-page-down',
                    ['<C-u>'] = 'preview-half-page-up',
                },
            },

            actions = {
                files = {
                    ['default'] = with_zz(actions.file_edit),
                    ['ctrl-t']  = with_zz(actions.file_tabedit),
                    ['ctrl-v']  = with_zz(actions.file_vsplit),
                    ['ctrl-x']  = with_zz(actions.file_split),
                    ['ctrl-q']  = ctrl_q_to_qf,
                    ['ctrl-a']  = ctrl_a_to_diff,
                },
            },

            files = {
                cmd = 'fd --type f --strip-cwd-prefix --hidden '
                    .. '--exclude .git --exclude node_modules --exclude tags',
                cwd_prompt = false,
            },

            grep = {
                rg_opts = '--hidden --column --line-number --no-heading '
                    .. '--color=always --smart-case --trim '
                    .. '--glob "!.git/*" --glob "!node_modules/*" --glob "!tags"',
                cwd_prompt = false,
            },

            buffers = {
                actions = {
                    ['default'] = with_zz(actions.buf_edit),
                    ['ctrl-t']  = with_zz(actions.buf_tabedit),
                    ['ctrl-v']  = with_zz(actions.buf_vsplit),
                    ['ctrl-x']  = with_zz(actions.buf_split),
                    -- Passing the action as a callback like this, automatically adds the interactive header hint
                    ['ctrl-c']  = { fn = actions.buf_del, reload = true },
                    ['ctrl-q']  = ctrl_q_to_qf,
                    ['ctrl-a']  = ctrl_a_to_diff,
                },
            },

            -- The tabs picker entries embed `tabh` and `winid`; switch focus via
            -- the API so existing split layouts (e.g. `:Git difftool -y`) stay
            -- intact. A picker-local `default` is required because the global
            -- `actions.files.default` above would otherwise win the merge in
            -- fzf-lua/config.lua and replace `buf_switch` with `file_edit`.
            tabs = {
                actions = {
                    ['default'] = function(selected)
                        local tabh, winid = selected[1]:match('(%d+)\t(%d+)%)')
                        tabh, winid = tonumber(tabh), tonumber(winid)
                        if not tabh then return end
                        vim.api.nvim_set_current_tabpage(tabh)
                        -- winid is 0 for the tab-title row; only window rows
                        -- carry a real winid worth restoring focus to.
                        if winid and winid ~= 0 then
                            vim.api.nvim_set_current_win(winid)
                        end
                        vim.cmd('wincmd =')
                    end,
                    ['ctrl-x'] = { fn = actions.buf_del, reload = true },
                },
            },

            git = {
                status = {
                    -- Replaces the default left/right arrow bindings with hjkl-aligned
                    -- equivalents: Ctrl-H unstages, Ctrl-L stages. The terminal-mode
                    -- buffer-local tmap shadows below carry these bytes through to
                    -- fzf even when vim-tmux-navigator owns the global mapping.
                    actions = {
                        ['default'] = with_zz(actions.file_edit_or_qf),
                        ['ctrl-h']  = { fn = actions.git_unstage, reload = true },
                        ['ctrl-l']  = { fn = actions.git_stage, reload = true },
                        ['ctrl-s']  = { fn = actions.git_stage_unstage, reload = true },
                        ['ctrl-x']  = { fn = actions.git_reset, reload = true },
                        ['ctrl-q']  = ctrl_q_to_qf,
                        ['ctrl-a']  = ctrl_a_to_diff,
                    },
                },
            },
        })

        -- Route vim.ui.select() through fzf-lua.
        --
        -- Function-form registration so every caller gets consistent UX:
        --   - The caller's prompt (e.g. "Select Adapter", "Select a help tag")
        --     becomes the picker's centered title on the border.
        --   - The custom '   ' icon stays as the input-line prompt.
        --   - The picker is sized compactly to its item count instead of
        --     inheriting the global 0.85x0.85 window (right for a files
        --     picker, absurd for a 5-item adapter selector).
        --   - LSP code actions (kind == 'codeaction') get a vertical layout
        --     with a diff preview underneath — the one ui.select flavor that
        --     genuinely benefits from a preview pane.
        --
        -- Pattern adapted from LazyVim's `ui_select` extra (see
        -- LazyVim/lua/lazyvim/plugins/extras/editor/fzf.lua).
        fzf.register_ui_select(function(fzf_opts, items)
            local title = vim.trim((fzf_opts.prompt or 'Select'):gsub('%s*:%s*$', ''))

            return vim.tbl_deep_extend('force', fzf_opts, {
                prompt = '   ',
                winopts = {
                    title     = ' ' .. title .. ' ',
                    title_pos = 'center',
                },
            }, fzf_opts.kind == 'codeaction' and {
                winopts = {
                    layout  = 'vertical',
                    width   = 0.5,
                    height  = math.floor(math.min(vim.o.lines * 0.8 - 16, #items + 4) + 0.5) + 16,
                    preview = {
                        layout   = 'vertical',
                        vertical = 'down:15,border-top',
                    },
                },
            } or {
                winopts = {
                    width  = 0.5,
                    height = math.floor(math.min(vim.o.lines * 0.8, #items + 4) + 0.5),
                },
            })
        end)

        -- Buffer-local keymaps for the fzf-lua terminal buffer:
        --
        --  Terminal-mode (<C-h/j/k/l>): vim-tmux-navigator installs *global*
        --  tmap mappings that route Ctrl-{h,j,k,l} to its TmuxNavigate*
        --  commands. Inside fzf-lua those would switch nvim/tmux panes
        --  instead of reaching fzf. Buffer-local tmap shadows the global
        --  one and forwards the literal byte to fzf via the terminal job
        --  channel — so Ctrl-J/K navigate the picker (per keymap.fzf above)
        --  and Ctrl-H/L do their fzf defaults (or the per-picker actions
        --  we configured, e.g. unstage/stage in git_status).
        vim.api.nvim_create_autocmd('FileType', {
            pattern  = 'fzf',
            group    = vim.api.nvim_create_augroup('fzf_lua_keys', { clear = true }),
            callback = function(args)
                local buf = args.buf
                local send = function(keys)
                    return function()
                        vim.api.nvim_chan_send(vim.b.terminal_job_id, vim.keycode(keys))
                    end
                end

                -- Shadow vim-tmux-navigator's global tmap inside fzf-lua.
                for _, key in ipairs({ '<C-h>', '<C-j>', '<C-k>', '<C-l>' }) do
                    vim.keymap.set('t', key, send(key), { buffer = buf, silent = true, nowait = true })
                end
            end,
        })
    end,
}
