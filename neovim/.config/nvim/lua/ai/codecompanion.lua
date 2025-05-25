return {
    'olimorris/codecompanion.nvim',
    lazy = true,
    event = 'VeryLazy',
    cmd = {
        'CodeCompanion',
        'CodeCompanionChat',
        'CodeCompanionActions',
        'CodeCompanionCmd',
    },
    keys = {
        { mode = { 'n', 'v' }, '<leader>aa', ':CodeCompanionActions<CR>', desc = 'Choose an LLM action' },
        { mode = { 'n', 'v' }, '<leader>ac', ':CodeCompanionChat<CR>', desc = 'Chat with LLMs' },
    },
    dependencies = {
        'nvim-lua/plenary.nvim',
        'nvim-treesitter/nvim-treesitter',
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
                                default = 'claude-3-7-sonnet-20250219',
                            },
                        },
                    })
                end,
            },
            strategies = {
                chat = {
                    adapter = 'ollama',
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
