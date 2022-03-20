local status_ok, lualine = pcall(require, 'lualine')
if not status_ok then
    vim.api.nvim_err_writeln('lualine not found')
    return
end

lualine.setup {
    options = {
        section_separators = { left = ' ', right = ' ' }, --                     
        component_separators = { left = '▎', right = ' ▎'}--{ left = '▎', right = '▎' },--
    },
    sections = {
        lualine_a = {'mode'},
        lualine_b = {'branch', 'diff'},
        lualine_c = {'filename'},
        lualine_x = {'diagnostics'},
        lualine_y = {'encoding', 'fileformat', 'filetype'},--{'progress'},--{'location'},
        lualine_z = {'progress'},
    },
}
