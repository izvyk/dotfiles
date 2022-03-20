local status_ok, monokai = pcall(require, 'monokai')
if not status_ok then
    vim.api.nvim_err_writeln('monokai colorscheme not found')
    return
end

monokai.setup { palette = require('monokai').pro } -- pro / soda / ristretto
