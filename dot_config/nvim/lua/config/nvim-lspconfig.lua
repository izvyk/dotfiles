local lspconfig = require'lspconfig'
local servers = { 'pyright', 'lua_ls', 'clangd', 'ltex' }

-- Use an on_attach function to only map the following keys after
-- the language server attaches to the current buffer
local on_attach = function(client, bufnr)
    local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end

    -- Mappings
    local opts = { noremap=true, silent=true }

    -- See `:help vim.lsp.*` for documentation on any of the below functions
    buf_set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
    buf_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
    buf_set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
    buf_set_keymap('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
    buf_set_keymap('n', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
    buf_set_keymap('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
    buf_set_keymap('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
    buf_set_keymap('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
    buf_set_keymap('n', '<space>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
    buf_set_keymap('n', '<space>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
    buf_set_keymap('n', '<space>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
    buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
    buf_set_keymap('n', '<space>e', '<cmd>lua vim.lsp.diagnostic.show_line_diagnostics()<CR>', opts)
    buf_set_keymap('n', '[d', '<cmd>lua vim.lsp.diagnostic.goto_prev()<CR>', opts)
    buf_set_keymap('n', ']d', '<cmd>lua vim.lsp.diagnostic.goto_next()<CR>', opts)
    buf_set_keymap('n', '<space>q', '<cmd>lua vim.lsp.diagnostic.set_loclist()<CR>', opts)
    buf_set_keymap('n', '<space>f', '<cmd>lua vim.lsp.buf.formatting()<CR>', opts)

    -- Disable Autoformat
    client.resolved_capabilities.document_formatting = true
    client.resolved_capabilities.document_range_formatting = true
end

for _, server in ipairs(servers) do
    -- applying special settings ONLY for nvim config files
    local full_file_path = vim.fn.expand('%:p') -- vim.loop.cwd() .. '/' .. vim.fn.expand('%')
    local nvim_config_path = vim.o.runtimepath:match('[^,]+') -- '/home/' .. os.getenv('USERNAME') .. '/.config/nvim/'
    if server == 'lua_ls' and string.find(full_file_path, nvim_config_path) ~= nil then
        lspconfig[server].setup {
            -- cmd = { 'lua-language-server', '--preview' },
            on_attach = on_attach,
            -- root_dir = function() return nvim_config_path end, -- nvim_config_path, -- vim.loop.cwd,
            settings = {
                Lua = {
                    runtime = {
                        -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
                        version = 'LuaJIT',
                    },
                    diagnostics = {
                        globals = { 'vim', 'use' },
                    },
                    workspace = {
                        -- maxPreload = 2000,
                        -- preloadFileSize = 2000,
                        library = {
                            library = vim.api.nvim_get_runtime_file('', true),
                        },
                    },
                    -- Do not send telemetry data containing a randomized but unique identifier
                   telemetry = {
                       enable = false,
                   }
                }
            }
        }
    else
        lspconfig[server].setup {
            an_attach = on_attach
        }
    end
end

vim.diagnostic.config({
    --update_in_insert = true,
    virtual_text = {
        prefix = '●', -- Could be '●', '▎', 'x', '', '■', ' ', ' ', ' ', ' ', ' ', '濫', '#', '綠', '雷', 'ﰉ ', 'ﰊ ', 'ﮋ ', '柳', 'ﱢ ', '栗', 'ﴵ ', '廓', '祈', 'ﳺ ', '', '', '', ' ', '', ''
    }
})

-- Set diganostic sign icons
-- https://github.com/neovim/nvim-lspconfig/wiki/UI-customization#change-diagnostic-symbols-in-the-sign-column-gutter
local signs = { Error = ' ', Warn = ' ', Hint = ' ', Info = ' ' }
--local signs = { Error = ' ', Warn = ' ', Hint = ' ', Info = ' ' }
for type, icon in pairs(signs) do
    local hl = 'DiagnosticSign' .. type
    vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end
