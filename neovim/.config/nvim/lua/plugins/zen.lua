return {
    'folke/zen-mode.nvim',
    lazy = true,
    cmd = { 'Zen', 'ZenMode' },
    dependencies = {
        'folke/twilight.nvim',
    },
    config = function()
        require('zen-mode').setup({
            window = {
                options = {
                    signcolumn = 'no',      -- disable signcolumn
                    colorcolumn = '',       -- disable 80 char column
                    number = false,         -- disable number column
                    relativenumber = false, -- disable relative numbers
                    cursorline = false,     -- disable cursorline
                    cursorcolumn = false,   -- disable cursor column
                    foldcolumn = '0',       -- disable fold column
                    list = false,           -- disable whitespace characters
                },
            },
            plugins = {
                options = {
                    enabled = true,
                    ruler = false,             -- disables the ruler text in the cmd line area
                    showcmd = false,           -- disables the command in the last line of the screen
                    laststatus = 0,            -- turn off the statusline in zen mode
                },
                twilight = { enabled = true }, -- enable to start Twilight when zen mode opens
                gitsigns = { enabled = true }, -- disables git signs
                tmux = { enabled = false },    -- disables the tmux statusline
                -- this will change the font size on alacritty when in zen mode
                -- requires  Alacritty Version 0.10.0 or higher
                -- uses `alacritty msg` subcommand to change font size
                alacritty = {
                    enabled = true,
                    font = '14', -- font size
                },
            },
        })
        vim.b.miniindentscope_disable = true
    end,
}
