return {
  {
    "github/copilot.vim",
    config = function()
      vim.g.copilot_filetypes = {
        ["markdown"] = false,
      }
      vim.keymap.set(
        "i",
        "<C-J>",
        'copilot#Accept("<CR>")',
        { expr = true, replace_keycodes = false }
      )
    end,
  },
  -- {
  --   "yetone/avante.nvim",
  --   lazy = false,
  --   version = false,
  --   build = "make",
  --   opts = {
  --     hints = { enabled = false }
  --   },
  --   dependencies = {
  --     "nvim-treesitter/nvim-treesitter",
  --     "stevearc/dressing.nvim",
  --     "nvim-lua/plenary.nvim",
  --     "MunifTanjim/nui.nvim",
  --   }
  -- }
}
