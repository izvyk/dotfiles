local cmd = vim.cmd
local g = vim.g
--[[
local function map(mode, l, r, opts)
    opts = opts or {}
    opts.buffer = bufnr
    vim.keymap.set(mode, l, r, opts)
end
]]

function map(mode, lhs, rhs, opts)
   local options = { noremap = true, silent = true }
   if opts then
      options = vim.tbl_extend('force', options, opts)
   end
   vim.api.nvim_set_keymap(mode, lhs, rhs, options)
end

g.mapleader = ' '

opts = { noremap = true, silent = true }
map('n', '<C-h>', '<C-w>h', opts)
map('n', '<C-j>', '<C-w>j', opts)
map('n', '<C-k>', '<C-w>k', opts)
map('n', '<C-l>', '<C-w>l', opts)


map('n', '<leader>t', ':NvimTreeToggle<CR>', {noremap = true})
-- map('n', '<leader>/', '

map('n', '<F5>', ':lua (vim.bo.filetype == \'NvimTree\') and (\'NvimTreeRefresh\') or (print(\'test\'))', opts)

cmd [[:tnoremap <Esc> <C-\><C-n>]]
cmd 'cabbrev vb vert sb'

M = {}

M.mappings = {
    nvim_tree = {
        tree_toggle = '<leader>tt',
        find_files_toggle = '<leader>tf',
        tree_refresh = '<F5>'
    }
}
