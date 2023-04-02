local fn = vim.fn
local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'

if fn.empty(fn.glob(install_path)) > 0 then
  packer_bootstrap = fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
  vim.cmd [[packadd packer.nvim]]
end

return require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'

  use {
    '/Users/rich/Projects/Personal/luacast',
    config = function()
      vim.cmd [[
        colorscheme luacast
      ]]
    end
  }

  use {
    'neovim/nvim-lspconfig',
    config = function()
      require('plugins.config.lspconfig')
    end
  }

  use {
    'hrsh7th/nvim-cmp',
    config = function()
      require('plugins.config/cmp')
    end
  }
  use 'hrsh7th/cmp-buffer'
  use 'hrsh7th/cmp-nvim-lsp'
  use 'saadparwaiz1/cmp_luasnip'
  use {
    'L3MON4D3/LuaSnip',
    config = function()
      require('luasnip').config.setup({})
    end
  }

  use {
    'lukas-reineke/indent-blankline.nvim',
    config = function()
      require('plugins.config.indent-blankline')
    end
  }

  use 'pbrisbin/vim-mkdir'

  use 'machakann/vim-sandwich'

  use {
    'numToStr/Comment.nvim',
    config = function()
      require('Comment').setup()
    end
  }

  use {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate',
    config = function()
      require('plugins.config.treesitter')
    end
  }
  use({
    'nvim-treesitter/nvim-treesitter-textobjects',
    after = 'nvim-treesitter',
    requires = 'nvim-treesitter/nvim-treesitter',
  })
  use 'nvim-treesitter/playground'

  use {
    'tpope/vim-rails',
    ft = {'ruby', 'eruby', 'haml', 'coffee'}
  }

  use {
    'junegunn/fzf',
  }
  use {
    'junegunn/fzf.vim',
    requires = {
      'nvim-lua/plenary.nvim'
    },
    config = function()
      require('plugins.config.fzf')
    end
  }

  use {
    'jose-elias-alvarez/null-ls.nvim',
    config = function()
      require('plugins.config.null-ls')
    end
  }

  use 'tpope/vim-fugitive'

  use {
    'stevearc/oil.nvim',
    config = function()
      require('oil').setup()
      vim.keymap.set("n", "-", require("oil").open, { desc = "Open parent directory" })
    end
  }
end)
