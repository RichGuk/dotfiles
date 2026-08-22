return {
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      -- Required here rather than at file scope: lazy.nvim evaluates spec files
      -- during startup, before catppuccin is on the runtimepath.
      local mocha = require("catppuccin.palettes").get_palette("mocha")

      -- Thanks to: https://github.com/dmmulroy
      -- Updated for Harpoon 2
      local function get_harpoon_status()
        local harpoon = require("harpoon")
        local total_marks = harpoon:list():length()

        if total_marks == 0 then
          return "󱡅 -/0"
        end

        local index = harpoon:list():get_current_index()
        local current_mark = "-"
        if index ~= -1 then
          current_mark = tostring(index)
        end

        return string.format("󱡅 %s/%s", current_mark, total_marks)
      end

      local custom_catppuccin = require("lualine.themes.catppuccin")
      custom_catppuccin.normal.c.bg = mocha.base
      custom_catppuccin.inactive.c.bg = mocha.crust

      require("lualine").setup({
        options = {
          theme = custom_catppuccin,
          globalstatus = true, -- belongs under `options`; ignored at top level
          component_separators = { left = "", right = "" },
          section_separators = { left = "", right = "" },
        },
        tabline = {
          lualine_a = {
            {
              "tabs",
              color = { bg = "none" },
              tabs_color = {
                active = {
                  bg = mocha.mantle,
                  fg = mocha.rosewater,
                  gui = "bold",
                },
                inactive = { bg = mocha.base, fg = mocha.overlay0 },
              },
              cond = function()
                return #vim.fn.gettabinfo() > 1
              end,
            },
          },
          lualine_z = {
            {
              "branch",
              icon = "",
              color = { bg = mocha.base, fg = mocha.rosewater },
              section_separators = { left = "", right = "" },
            },
          },
        },
        sections = {
          lualine_a = {},
          lualine_b = { get_harpoon_status, "diff", "diagnostics" },
          lualine_c = {
            {
              "filename",
              path = 1,
            },
          },
          lualine_x = { "filetype" },
          lualine_y = {},
          lualine_z = {},
        },
        inactive_sections = {
          lualine_c = {
            {
              "filename",
              path = 1,
            },
          },
        },
      })
    end,
  },
}
