require'nvim-web-devicons'.setup {
    override = {
        ["js"] = {
            icon = "",
            color = "#f7dd4a",
            cterm_color = "185",
            name = "Js"
        },
        ["ts"] = {
            icon = "ﯤ",
            color = "#4477c0",
            cterm_color = "67",
            name = "Ts",
        },
        ["html"] = {
            icon = "",
            color = "#e34c26",
            cterm_color = "166",
            name = "Html",
        },
        ["css"] = {
            icon = "",
            color = "#3771b5",
            cterm_color = "60",
            name = "Css",
        },
        ["git"] = {
            icon = "",
            color = "#e45a38",
            cterm_color = "59",
            name = "GitIgnore",
        },
        [".gitattributes"] = {
            icon = "",
            color = "#e45a38",
            cterm_color = "59",
            name = "GitIgnore",
        },
        [".gitignore"] = {
            icon = "",
            color = "#e45a38",
            cterm_color = "59",
            name = "GitIgnore",
        },
        [".gitmodules"] = {
            icon = "",
            color = "#e45a38",
            cterm_color = "59",
            name = "GitIgnore",
        },
        ["COMMIT_EDITMSG"] = {
            icon = "",
            color = "#e45a38",
            cterm_color = "59",
            name = "GitIgnore",
        },
        ["sh"] = {
            icon = "",
            color = "#4daab7",
            cterm_color = "59",
            name = "Sh",
        },
    };
    -- globally enable default icons (default to false)
    -- will get overriden by `get_icons` option
    default = true;
}
