return {
    'olimorris/codecompanion.nvim',
    lazy = true,
    event = 'VeryLazy',
    cmd = {
        'CodeCompanion',
        'CodeCompanionChat',
        'CodeCompanionActions',
        'CodeCompanionCmd',
        'CodeCompanionHistory',
    },
    keys = {
        { mode = { 'n', 'v' }, '<leader>aa', ':CodeCompanionActions<CR>',     desc = 'Choose an LLM action' },
        { mode = { 'n', 'v' }, '<leader>ac', ':CodeCompanionChat Toggle<CR>', desc = 'Chat with LLMs' },
        { mode = { 'n', 'v' }, '<leader>ah', ':CodeCompanionHistory<CR>',     desc = 'Open LLM chat history' },
    },
    dependencies = {
        'nvim-lua/plenary.nvim',
        'ravitemer/codecompanion-history.nvim',
        'ravitemer/mcphub.nvim',
    },
    config = function()
        -- Workaround: CodeCompanion's slash-command FZF provider sets the
        -- picker prompt to args.title (e.g. "Select a help tag" for /help),
        -- bypassing our fzf-lua register_ui_select callback. Patch its
        -- display() to move the title to the border and keep our custom
        -- prompt symbol. Touches a soft (private-ish) API, so revisit if
        -- codecompanion changes its provider shape.
        do
            local cc_fzf = require('codecompanion.providers.slash_commands.fzf_lua')
            local original_display = cc_fzf.display
            cc_fzf.display = function(self, transformer)
                local opts = original_display(self, transformer)
                local title = vim.trim((opts.prompt or 'Select'):gsub('%s*:%s*$', ''))
                opts.prompt = '   '
                opts.winopts = vim.tbl_deep_extend('force', opts.winopts or {}, {
                    title     = ' ' .. title .. ' ',
                    title_pos = 'center',
                })
                return opts
            end
        end

        require('codecompanion').setup({
            adapters = {
                http = {
                    opts = {
                        show_presets = false, -- Hide preset adapters
                        show_model_choices = true,
                    },
                    ollama = require('ai.adapters.ollama'),
                    openai = require('ai.adapters.openai'),
                    anthropic = require('ai.adapters.anthropic'),
                },
                acp = {
                    opts = {
                        show_presets = false, -- Hide preset adapters
                        show_model_choices = true,
                    },
                    gemini_cli = require('ai.adapters.gemini_cli'),
                    claude_code = require('ai.adapters.claude_code'),
                }
            },
            strategies = {
                chat = {
                    opts = {
                        goto_file_action = require('ai.helpers.goto_previously_focused_win'),
                    },
                    keymaps = {
                        fold_code = {
                            modes = { n = "gF", },
                        },
                        goto_file_under_cursor = {
                            modes = { n = "gf", },
                        },
                    },
                    adapter = 'anthropic',
                    roles = {
                        ---The header name for the LLM's messages
                        llm = function(adapter)
                            return '󱙺  ' .. adapter.formatted_name .. ' (' .. adapter.schema.model.default .. ')'
                        end,

                        ---The header name for your messages
                        ---@type string
                        user = '  Me',
                    },
                    tools = {
                        opts = {
                            default_tools = { 'files', }
                        }
                    }
                },
                inline = {
                    adapter = 'ollama',
                },
            },
            extensions = {
                history = {
                    enabled = true,
                    opts = {
                        -- Keymap to open history from chat buffer (default: gh)
                        keymap = 'gh',
                        -- Keymap to save the current chat manually (when auto_save is disabled)
                        save_chat_keymap = 'sc',
                        -- Save all chats by default (disable to save only manually using 'sc')
                        auto_save = true,
                        -- Number of days after which chats are automatically deleted (0 to disable)
                        expiration_days = 0,
                        ---Automatically generate titles for new chats
                        auto_generate_title = true,
                        ---Title generation defaults to the current chat adapter,
                        ---which fails when the chat is on an ACP adapter (e.g.
                        ---claude_code). Pin to ollama (local, HTTP) — title
                        ---generation is a cheap one-shot and runs offline.
                        ---Model must be explicit too: when only `adapter` is
                        ---overridden, the title generator otherwise reuses the
                        ---chat's model name (e.g. claude-opus-4-7) which ollama
                        ---doesn't have.
                        title_generation_opts = {
                            adapter = 'ollama',
                            model   = 'qwen2.5:1.5b',
                        },
                        ---On exiting and entering neovim, loads the last chat on opening chat
                        continue_last_chat = false,
                        ---When chat is cleared with `gx` delete the chat from history
                        delete_on_clearing_chat = false,
                        ---Directory path to save the chats
                        dir_to_save = vim.fn.stdpath('data') .. '/codecompanion-history',
                    }
                },
                mcphub = {
                    callback = 'mcphub.extensions.codecompanion',
                    opts = {
                        -- TODO: re-enable once ravitemer/mcphub.nvim#275 is fixed
                        -- (reads removed config.interactions.chat.variables on codecompanion v19)
                        make_vars = false,
                        make_slash_commands = true,
                        show_result_in_chat = true
                    }
                }
            },
            prompt_library = {
                ['  Study buddy: computer networking'] = require('ai.prompts.computer-networking'),
                ['  General purpose assistant'] = require('ai.prompts.general-purpose-assistant'),
            },
            display = {
                chat = {
                    show_header_separator = false,
                    fold_context = false,
                    fold_reasoning = true,
                },
                action_palette = {
                    opts = {
                        show_preset_actions = true,        -- Show the preset actions in the action palette?
                        show_preset_prompt_library = true, -- Show the preset prompt library in the action palette?
                    }
                },
            },
        })
    end,
    init = function()
        require('ai.helpers.spinner'):init()
    end,
}
