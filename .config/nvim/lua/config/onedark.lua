local status_ok, onedark = pcall(require, 'onedark')
if not status_ok then
    vim.api.nvim_err_writeln('onedark colorscheme not found')
    return
end

onedark.setup {
        style = 'warmer', -- Choose between 'dark', 'darker', 'cool', 'deep', 'war    m', 'warmer' and 'light'
--        transparent = true,
}
require('onedark').load()
