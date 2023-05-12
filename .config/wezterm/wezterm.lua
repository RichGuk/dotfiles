local wezterm = require 'wezterm'

local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

config.term = 'wezterm'

config.front_end = 'WebGpu'

config.font = wezterm.font('FiraCode Nerd Font')
config.harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' }
config.font_size = 16

config.window_background_opacity = 0.90
config.macos_window_background_blur = 30
-- config.color_scheme = 'kanagawabones'

local scheme = wezterm.get_builtin_color_schemes()['Snazzy']
-- scheme.background = '#16222f'
scheme.background = '#031926'

local schemec = wezterm.get_builtin_color_schemes()['Catppuccin Mocha']
-- scheme.background = '#16222f'
schemec.background = '#171622'

config.color_schemes = {
  ['Snazzy'] = scheme,
  ['Catppuccin Mocha'] = schemec,
}
-- config.color_scheme = 'Snazzy'

config.color_scheme = 'Catppuccin Mocha'

config.colors = {
  tab_bar = {
    active_tab = {
      bg_color = '#313244',
      fg_color = '#9399b2',
      italic = false,
    },
    inactive_tab = {
      bg_color = '#181825',
      fg_color = '#45475a',
    },
    inactive_tab_hover = {
      bg_color = '#313244',
      fg_color = '#9399b2',
      italic = true,
    },
  },
}

config.window_frame = {
  active_titlebar_bg = '#171622',
  inactive_titlebar_bg = '#16222f',
}

config.hide_tab_bar_if_only_one_tab = true
config.show_new_tab_button_in_tab_bar = false
config.window_decorations = 'RESIZE'

config.audible_bell = 'Disabled'

return config
