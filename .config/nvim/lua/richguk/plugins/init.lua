return {
  {
    'numToStr/Comment.nvim',
    lazy = false,
    config = function()
      require('Comment').setup({})
    end
  },
  'pbrisbin/vim-mkdir',
  'machakann/vim-sandwich',
  'tpope/vim-fugitive',
  'christoomey/vim-tmux-navigator',
}
