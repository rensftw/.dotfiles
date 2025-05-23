return {
    'David-Kunz/gen.nvim',
    lazy = true,
    cmd = { 'Gen' },
    dependencies = {
        'nvim-telescope/telescope-ui-select.nvim'
    },
    keys = {
        { mode = { 'n', 'v' }, '<leader>aa', ':Gen<CR>', desc = 'Select interaction mode with a local LLM' },
        { mode = { 'n', 'v' }, '<leader>ac', ':Gen Chat<CR>', desc = 'Chat with local LLM' },
        { mode = { 'n', 'v' }, '<leader>am', function() require('gen').select_model() end, desc = 'Select local LLM to interact with' },
    },
    config = function()
        local gen = require('gen')
        gen.setup({
            model = 'qwen2.5-coder:7b',      -- The default model to use.
            display_mode = 'split', -- The display mode. Can be 'float' or 'split'.
            show_prompt = true,     -- Shows the Prompt submitted to Ollama.
            show_model = true,      -- Displays which model you are using at the beginning of your chat session.
            no_auto_close = false,  -- Never closes the window automatically.
            debug = false           -- Prints errors and the command which is run.
        })
    end
}
