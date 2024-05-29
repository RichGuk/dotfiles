local wezterm = require("wezterm")

local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- config.term = 'wezterm'

config.front_end = "OpenGL"
-- config.max_fps = 144

config.font = wezterm.font("FiraCode Nerd Font")
config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }
config.font_size = 16

config.window_background_opacity = 0.95
config.macos_window_background_blur = 30

config.send_composed_key_when_left_alt_is_pressed = true

local schemec = wezterm.get_builtin_color_schemes()["Catppuccin Mocha"]
schemec.background = "#1e1e2e"

config.color_schemes = {
  ["Catppuccin Mocha"] = schemec,
}

config.color_scheme = "Catppuccin Mocha"

config.window_frame = {
  active_titlebar_bg = "rgba(30, 30, 46, 0.95)",
  inactive_titlebar_bg = "rgba(30, 30, 46, 0.95)",
}

config.colors = {
  tab_bar = {
    active_tab = {
      bg_color = "#313244",
      fg_color = "#9399b2",
      italic = false,
    },
    inactive_tab = {
      bg_color = "#181825",
      fg_color = "#45475a",
    },
    inactive_tab_hover = {
      bg_color = "#313244",
      fg_color = "#9399b2",
      italic = true,
    },
  },
}

config.hide_tab_bar_if_only_one_tab = true
config.show_new_tab_button_in_tab_bar = false
config.window_decorations = "RESIZE"

config.audible_bell = "Disabled"

config.keys = {}

for i = 1, 8 do
  -- CTRL+ALT + number to move to that position
  table.insert(config.keys, {
    key = tostring(i),
    mods = "CTRL|ALT",
    action = wezterm.action.MoveTab(i - 1),
  })
end

return config
