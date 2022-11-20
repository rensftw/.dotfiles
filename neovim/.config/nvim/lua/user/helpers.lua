local M = {}

Virtual_text = {}
Virtual_text.show = true
Virtual_text.toggle = function()
    Virtual_text.show = not Virtual_text.show
    vim.diagnostic.config({
        virtual_text = Virtual_text.show,
        underline = Virtual_text.show,
        update_in_insert = true,
        severity_sort = true,
    })
end

M.Virtual_text = Virtual_text
return M
