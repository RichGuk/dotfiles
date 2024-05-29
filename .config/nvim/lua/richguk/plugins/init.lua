return {
  { "numToStr/Comment.nvim", lazy = false, config = true },
  { "echasnovski/mini.surround", version = false, config = true },
  {
    "FabijanZulj/blame.nvim",
    config = function()
      require("blame").setup()
    end,
  },
  "christoomey/vim-tmux-navigator",
}
