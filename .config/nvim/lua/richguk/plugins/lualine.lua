return {
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      local custom_catppuccin = require('lualine.themes.catppuccin')
      custom_catppuccin.normal.c.bg = '#11111b'
      custom_catppuccin.inactive.c.bg = '#181825'

      require('lualine').setup({
        options = { theme = custom_catppuccin },
        globalstatus = true,
        tabline = {
          lualine_a = { 'tabs' },
          lualine_z = { 'branch' }
        },
        sections = {
          lualine_a = { 'mode' },
          lualine_b = { 'diff', 'diagnostics' },
          lualine_c = {
            {
              'filename',
              path = 1,
            }
          },
          lualine_x = { 'encoding', 'fileformat', 'filetype' },
          lualine_y = { 'progress' },
          lualine_z = { 'location' }
        },
        inactive_sections = {
          lualine_c = {
            {
              'filename',
              path = 1,
            }
          },
        },
      })
    end
  },
}
