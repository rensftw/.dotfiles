return {
    'David-Kunz/gen.nvim',
    lazy = true,
    cmd = { 'Gen' },
    config = function()
        require('gen').setup({
            model = 'mistral',      -- The default model to use.
            display_mode = 'float', -- The display mode. Can be 'float' or 'split'.
            show_prompt = true,     -- Shows the Prompt submitted to Ollama.
            show_model = true,      -- Displays which model you are using at the beginning of your chat session.
            no_auto_close = false,  -- Never closes the window automatically.
            debug = false           -- Prints errors and the command which is run.
        })
    end
}
