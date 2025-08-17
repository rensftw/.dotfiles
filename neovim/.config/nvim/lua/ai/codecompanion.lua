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
        { mode = { 'n', 'v' }, '<leader>aa', ':CodeCompanionActions<CR>', desc = 'Choose an LLM action' },
        { mode = { 'n', 'v' }, '<leader>ac', ':CodeCompanionChat Toggle<CR>', desc = 'Chat with LLMs' },
        { mode = { 'n', 'v' }, '<leader>ah', ':CodeCompanionHistory<CR>', desc = 'Open LLM chat history' },
    },
    dependencies = {
        'nvim-lua/plenary.nvim',
        'nvim-treesitter/nvim-treesitter',
        'ravitemer/codecompanion-history.nvim',
        'ravitemer/mcphub.nvim',
    },
    config = function()
        require('codecompanion').setup({
            adapters = {
                opts = {
                    show_defaults = false,  -- Hide default adapters
                    show_model_choices = true,
                },
                ollama = function()
                    return require('codecompanion.adapters').extend('ollama', {
                        name = 'ollama',
                        schema = {
                            model = {
                                default = 'qwen2.5-coder:7b',
                            },
                        },
                    })
                end,
                openai = function()
                    return require('codecompanion.adapters').extend('openai', {
                        name = 'openai',
                        env = {
                            api_key = 'cmd:pass show OPENAI_API_KEY',
                        },
                        schema = {
                            model = {
                                default = 'gpt-4o',
                            },
                        },
                    })
                end,
                anthropic = function()
                    return require('codecompanion.adapters').extend('anthropic', {
                        name = 'anthropic',
                        env = {
                            api_key = 'cmd:pass show ANTHROPIC_API_KEY',
                        },
                        schema = {
                            model = {
                                default = 'claude-sonnet-4-20250514',
                            },
                        },
                    })
                end,
            },
            strategies = {
                chat = {
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
                        make_vars = true,
                        make_slash_commands = true,
                        show_result_in_chat = true
                    }
                }
            },
            prompt_library = {
                ['Study buddy: computer networking'] = require('ai.utils.prompt_computer-networking'),
            },
            display = {
                chat = {
                    show_header_separator = false,
                },
                action_palette = {
                    show_default_actions = true, -- Show the default actions in the action palette?
                    show_default_prompt_library = true, -- Show the default prompt library in the action palette?
                },
            }
        })
    end,
    init = function()
        require('ai.utils.spinner'):init()
    end,
}
