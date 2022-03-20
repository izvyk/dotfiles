local status_ok, bufferline = pcall(require, 'bufferline')
if not status_ok then
    vim.api.nvim_err_writeln('bufferline not found')
    return
end

bufferline.setup {
    options = {
        separator_style = { '', '' },
        show_close_icon = false,
        diagnostics = 'nvim_lsp',
    }
}
