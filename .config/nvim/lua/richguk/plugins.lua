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

  use { 'catppuccin/nvim', as = 'catppuccin' }

  use { 'neovim/nvim-lspconfig' }

  use { 'hrsh7th/nvim-cmp' }

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

  use { 'lukas-reineke/indent-blankline.nvim' }

  use 'pbrisbin/vim-mkdir'

  use 'machakann/vim-sandwich'

  use { 'numToStr/Comment.nvim' }

  use {
    'nvim-treesitter/nvim-treesitter',
    run = function()
      local ts_update = require('nvim-treesitter.install').update({ with_sync = true })
      ts_update()
    end
  }

  use {
    'nvim-treesitter/nvim-treesitter-textobjects',
    after = 'nvim-treesitter',
    requires = 'nvim-treesitter/nvim-treesitter',
  }
  use {
    'RRethy/nvim-treesitter-endwise',
    after = 'nvim-treesitter',
    requires = 'nvim-treesitter/nvim-treesitter',
  }

  use { 'ibhagwan/fzf-lua', requires = { 'nvim-tree/nvim-web-devicons' } }
  use { 'junegunn/fzf', run = './install --bin', }

  use { 'jose-elias-alvarez/null-ls.nvim', requires = { 'nvim-lua/plenary.nvim' } }

  use 'tpope/vim-fugitive'

  use { 'stevearc/oil.nvim' }

  use {
    'nvim-lualine/lualine.nvim',
    requires = { 'nvim-tree/nvim-web-devicons', opt = true },
  }

  if packer_bootstrap then
    require('packer').sync()
  end
end)
