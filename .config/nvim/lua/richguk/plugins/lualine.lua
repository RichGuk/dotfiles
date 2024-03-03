return {
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local harpoon = require("harpoon")

      -- Thanks to: https://github.com/dmmulroy
      -- Updated for Harpoon 2
      local function get_harpoon_status()
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
      custom_catppuccin.normal.c.bg = "#181825"
      custom_catppuccin.inactive.c.bg = "#313244"

      require("lualine").setup({
        options = {
          theme = custom_catppuccin,
          component_separators = { left = "", right = "" },
          section_separators = { left = "", right = "" },
        },
        globalstatus = true,
        tabline = {
          lualine_a = {
            {
              "tabs",
              color = { bg = "none" },
              tabs_color = {
                active = {
                  bg = "#585b70",
                  fg = "#bac2de",
                  gui = "bold",
                },
                inactive = { bg = "#1e1e2e", fg = "#a6adc8" },
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
              color = { bg = "#181825", fg = "#a6adc8" },
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
