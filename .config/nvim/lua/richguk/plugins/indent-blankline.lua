return {
  "lukas-reineke/indent-blankline.nvim",
  config = function()
    require("ibl").setup({
      indent = { char = "¦", highlight = { "CursorLineSign" } },
      scope = { highlight = { "CursorLineFold" } },
    })
  end,
}
