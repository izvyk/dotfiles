local status_ok, comment = pcall(require, 'Comment')
if not status_ok then
    vim.api.nvim_err_writeln('Comment.nvim not found')
    return
end

comment.setup()
