local wezterm = require 'wezterm'

local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

config.front_end = 'WebGpu'

config.font = wezterm.font('Fira Code')
config.harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' }
config.font_size = 16

config.window_background_opacity = 0.90
config.macos_window_background_blur = 30
-- config.color_scheme = 'kanagawabones'

local scheme = wezterm.get_builtin_color_schemes()['PaleNightHC']
scheme.background = '#16222f'

config.color_schemes = {
  ['PaleNightHC'] = scheme,
  -- ['kanagawabones'] = {
  --   background = '#16222f',
  -- },
}
config.color_scheme = 'PaleNightHC'

config.colors = {
  tab_bar = {
    active_tab = {
      bg_color = '#131d29',
      fg_color = '#446c9c',
      italic = false,
    },
    inactive_tab = {
      bg_color = '#131d29',
      fg_color = '#2a425e',
    },
    inactive_tab_hover = {
      bg_color = '#1a293b',
      fg_color = '#2a425e',
      italic = true,
    },
  },
}

config.window_frame = {
  active_titlebar_bg = '#15212e',
  inactive_titlebar_bg = '#16222f',
}

config.hide_tab_bar_if_only_one_tab = true
config.show_new_tab_button_in_tab_bar = false
config.window_decorations = 'RESIZE'

config.audible_bell = 'Disabled'

return config
