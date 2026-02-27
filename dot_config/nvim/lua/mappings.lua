local cmd = vim.cmd
local g = vim.g

local function map(mode, lhs, rhs, opts)
    opts = opts or { noremap = true, silent = true }
    vim.api.nvim_set_keymap(mode, lhs, rhs, opts)
end

g.mapleader = ' '
g.maplocalleader = ' '

map('n', '<C-h>', '<C-w>h')
map('n', '<C-j>', '<C-w>j')
map('n', '<C-k>', '<C-w>k')
map('n', '<C-l>', '<C-w>l')

-- Layout switching fix
map('i', '<D-Space>', '<Nop>')
map('n', '<D-Space>', '<Nop>')
map('v', '<D-Space>', '<Nop>')
map('t', '<D-Space>', '<Nop>')

map('t', '<Esc><Esc>', '<C-\\><C-n>')


-- TIP: Disable arrow keys in normal mode
map('n', '<left>', '<cmd>echo "Use h to move!"<CR>')
map('n', '<right>', '<cmd>echo "Use l to move!"<CR>')
map('n', '<up>', '<cmd>echo "Use k to move!"<CR>')
map('n', '<down>', '<cmd>echo "Use j to move!"<CR>')


vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
