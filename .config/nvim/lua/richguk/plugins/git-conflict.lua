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
  cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles", "DiffviewFileHistory" },
  config = function()
    local actions = require("diffview.actions")

    require("diffview").setup({
      view = {
        default = {
          disable_diagnostics = true,
        },
        merge_tool = {
          layout = "diff3_mixed",
        },
      },
      keymaps = {
        view = {
          { "n", "co",  actions.conflict_choose("ours"),        { desc = "Choose the OURS version of a conflict" } },
          { "n", "ct",  actions.conflict_choose("theirs"),      { desc = "Choose the THEIRS version of a conflict" } },
          { "n", "ce",  actions.conflict_choose("base"),        { desc = "Choose the BASE version of a conflict" } },
        },
      },
    })
  end,
}
