local o = vim.opt -- Equal to :set
local g = vim.g
--local bo = vim.bo -- Equal to :setlocal
--local go = vim.go -- Equal to :setglobal
local cmd = vim.cmd

-- misc
o.mouse = 'a' -- Enable mouse in all modes
o.number = true -- Show row numbers
-- o.relativenumber = true
o.scrolloff = 5 -- Cursor is always 5 lines below and above the edge of the screen
o.cursorline = true -- Highlight cursor line
-- o.colorcolumn = '80' -- Highlight 80th column
o.history = 3000 -- Instead of default 10000
o.showmode = false
o.laststatus = 3 -- global statusline
o.shortmess = 'a'
vim.opt.updatetime = 250

-- Search
o.ignorecase = true -- Case-insensitive search
o.incsearch = true -- Search before 'Enter' hit
o.smartcase = true -- Search case-sensitive if uppercase exists
o.wrapscan = true -- Make search cyclic

-- encoding
o.fileencodings = 'utf-8,cp1251,koi8-r,cp866'

-- Preview commands
vim.opt.inccommand = 'split'

-- tabs
o.tabstop = 4
o.shiftwidth = 4
o.softtabstop = 4
o.expandtab = true -- Replace tabs with whitespaces
o.smarttab = true
o.autoindent = true
o.smartindent = true


-- linebreaks
o.linebreak = true
o.breakindent = true
o.showbreak = '↳ '

-- Undo
vim.opt.undofile = true

--
g.have_nerd_font = true
o.signcolumn = 'yes'
o.list = true
o.listchars = { tab = '  ', trail = '·', nbsp = '␣', extends = '>' }
-- o.listchars = { tab = '<->', multispace = '·', trail = '·', nbsp = '␣', extends = '>' }


vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Briefly highlight yanked text',
    group = vim.api.nvim_create_augroup('highlight-yank', { clear = true }),
    callback = function()
        vim.highlight.on_yank({ higroup = 'Visual', timeout = 300 })
    end,
})

-- langmap configuration
local function escape(str)
  -- You need to escape these characters to work correctly
  local escape_chars = [[;,."|\]]
  return vim.fn.escape(str, escape_chars)
end

local en = [[`qwertyuiop[]asdfghjkl;'zxcvbnm]]
local ru = [[ёйцукенгшщзхъфывапролджэячсмить]]
local en_shift = [[~QWERTYUIOP{}ASDFGHJKL:"ZXCVBNM<>]]
local ru_shift = [[ËЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮ]]

vim.opt.langmap = vim.fn.join({ escape(ru_shift) .. ";" .. escape(en_shift), escape(ru) .. ";" .. escape(en) }, ",")
