local status_ok, packer = pcall(require, 'packer')
if not status_ok then
    return
end

packer.startup(function()
    use 'wbthomason/packer.nvim'
--    use 'karb94/neoscroll.nvim'
--    use 'ellisonleao/gruvbox.nvim'
--    use { 'wittyjudge/gruvbox-material.nvim', disabled = true }
--    use { 'navarasu/onedark.nvim', disabled = false }
--    use { 'projekt0n/github-nvim-theme', disabled = true }
    use { 'tanvirtin/monokai.nvim', 
        config = function() require('config.monokai') end,
    }
    use 'neovim/nvim-lspconfig'
    use { 'nvim-treesitter/nvim-treesitter', build = ':TSUpdate' }
	use { 'nvim-lualine/lualine.nvim',
        requires = { 'kyazdani42/nvim-web-devicons',
            opt = true,
        },
        config = function() require('config.lualine') end,
    }
   use { 'kyazdani42/nvim-tree.lua',
       requires = {
           'kyazdani42/nvim-web-devicons',
       },
       config = function() require'nvim-tree'.setup {} end,
   }
    use { 'nvim-telescope/telescope.nvim',
       disabled = true,
       requires = {
           'nvim-lua/plenary.nvim',
           { 'nvim-telescope/telescope-fzf-native.nvim', run = 'make' }
       },
       config = function() require('config.telescope') end,
   }
   use {
        "folke/which-key.nvim",
        config = function() require('config.which-key') end,
    }
--    use { 'lukas-reineke/lsp-format.nvim' }
    use { 'numToStr/Comment.nvim',
        config = function() require('config.comment') end,
    }
--    use { 'hrsh7th/nvim-cmp',
--        requires = {
--            'neovim/nvim-lspconfig',
--            'hrsh7th/cmp-nvim-lsp',
--            'hrsh7th/cmp-buffer',
--            'hrsh7th/cmp-path',
--            'hrsh7th/cmp-cmdline',
--        }
--    }
end)
