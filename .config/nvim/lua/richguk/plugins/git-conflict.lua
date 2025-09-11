-- return {
--   "akinsho/git-conflict.nvim",
--   version = "*",
--   config = function()
--     require("git-conflict").setup({
--       disable_diagnostics = true,
--     })
--   end,
-- }
--

return {
  "sindrets/diffview.nvim",
  config = function()
    require("diffview").setup({})
  end,
}
