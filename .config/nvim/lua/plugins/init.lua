local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()

return require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'

  -- use {
  --   'RichGuk/luacast',
  --   config = function()
  --     vim.cmd.colorscheme('luacast')
  --     vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
  --     vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
  --   end
  -- }
  use {
    'catppuccin/nvim',
    as = 'catppuccin',
    config = function()
      require('plugins.config.catppuccin')
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
      require("luasnip.loaders.from_vscode").lazy_load()
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
  use 'RRethy/nvim-treesitter-endwise'

  use { 'ibhagwan/fzf-lua',
    requires = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('plugins.config.fzf')
    end
  }
  use { 'junegunn/fzf', run = './install --bin', }

  use {
    'jose-elias-alvarez/null-ls.nvim',
    config = function()
      require('plugins.config.null-ls')
    end,
    requires = {
      'nvim-lua/plenary.nvim',
    },
  }

  use 'tpope/vim-fugitive'

  use {
    'stevearc/oil.nvim',
    config = function()
      require('oil').setup()
      vim.keymap.set('n', '-', require('oil').open, { desc = 'Open parent directory' })
    end
  }

  use {
    'nvim-lualine/lualine.nvim',
    requires = { 'nvim-tree/nvim-web-devicons', opt = true },
    config = function()
      require('plugins.config.lualine')
    end
  }

  if packer_bootstrap then
    require('packer').sync()
  end
end)
