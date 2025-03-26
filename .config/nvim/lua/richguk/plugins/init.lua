return {
  {
    "folke/ts-comments.nvim",
    opts = {},
    event = "VeryLazy",
    enabled = vim.fn.has("nvim-0.10.0") == 1,
  },
  { "echasnovski/mini.surround", version = false, config = true },
  {
    "FabijanZulj/blame.nvim",
    config = function()
      require("blame").setup()
    end,
  },
  "christoomey/vim-tmux-navigator",
}

