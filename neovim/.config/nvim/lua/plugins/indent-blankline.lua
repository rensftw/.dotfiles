return {
    'lukas-reineke/indent-blankline.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
        require('ibl').setup {
            indent = {
                char = '▏',
            },
            exclude = {
                buftypes = {
                    'terminal',
                    'nofile',
                    'quickfix',
                    'prompt',
                },
                filetypes = {
                    'checkhealth',
                    'lspinfo',
                    'help',
                    'man',
                    'packer',
                    'mason',
                    'alpha',
                },
            },
            scope = {
                include = {
                    -- source: https://github.com/lukas-reineke/indent-blankline.nvim/issues/632#issuecomment-1732366788
                    node_type = {
                        lua = {
                            'chunk',
                            'do_statement',
                            'while_statement',
                            'repeat_statement',
                            'if_statement',
                            'for_statement',
                            'function_declaration',
                            'function_definition',
                            'table_constructor',
                            'assignment_statement',
                        },
                        typescript = {
                            'statement_block',
                            'function',
                            'arrow_function',
                            'function_declaration',
                            'method_definition',
                            'for_statement',
                            'for_in_statement',
                            'catch_clause',
                            'object_pattern',
                            'arguments',
                            'switch_case',
                            'switch_statement',
                            'switch_default',
                            'object',
                            'object_type',
                            'ternary_expression',
                        },
                    },
                }
            },
        }
    end
}
