return {
  {
    "folke/ts-comments.nvim",
    opts = {},
    event = "VeryLazy",
    enabled = vim.fn.has("nvim-0.10.0") == 1,
  },
  { "echasnovski/mini.surround", version = false, config = true, event = "VeryLazy" },
  {
    "FabijanZulj/blame.nvim",
    cmd = { "BlameToggle" },
    opts = {},
  },
  {
    "christoomey/vim-tmux-navigator",
    -- vim-herdr-navigation owns <C-hjkl> and calls these commands for the tmux
    -- fallback. Suppress this plugin's own mappings rather than relying on load
    -- order to overwrite them.
    init = function()
      vim.g.tmux_navigator_no_mappings = 1
    end,
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
    },
  },
  {
    -- Not a conventional plugin layout: the Neovim side is a single file at
    -- editor/nvim.lua, so lazy clones the repo and we source it ourselves.
    -- Needs the herdr-side plugin too: herdr plugin install paulbkim-dev/vim-herdr-navigation
    "paulbkim-dev/vim-herdr-navigation",
    dependencies = { "christoomey/vim-tmux-navigator" },
    lazy = false,
    config = function()
      dofile(vim.fn.stdpath("data") .. "/lazy/vim-herdr-navigation/editor/nvim.lua")
    end,
  },
}

