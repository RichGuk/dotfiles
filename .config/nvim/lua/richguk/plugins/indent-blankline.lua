return {
  "lukas-reineke/indent-blankline.nvim",
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    vim.api.nvim_set_hl(0, "IblScope", { fg = "#a6adc8" })

    require("ibl").setup({
      indent = { char = "¦", highlight = { "CursorLineSign" } },
    })
  end,
}
