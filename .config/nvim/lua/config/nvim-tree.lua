local status_ok, nvim_tree = pcall(require, 'nvim-tree')
if not status_ok then
    vim.api.nvim_err_writeln('nvim-tree not found')
    return
end

-- local maps = require('mappings').M.mappings.nvim_tree


nvim_tree.setup {
    open_on_setup = true,
    hijack_cursor = true,
    auto_close = true,

}

-- local map = require('mappings').map
--
-- map('n', 

