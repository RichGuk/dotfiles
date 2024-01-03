return {
  {
    'numToStr/Comment.nvim',
    lazy = false,
    config = function()
      require('Comment').setup({})
    end
  },
  'pbrisbin/vim-mkdir',
  'tpope/vim-fugitive',
  'christoomey/vim-tmux-navigator',
}
