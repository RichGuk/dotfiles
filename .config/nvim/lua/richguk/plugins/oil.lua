return {
  "stevearc/oil.nvim",
  keys = {
    { "-", function() require("oil").open() end, desc = "Open parent directory" },
  },
  opts = {},
}
