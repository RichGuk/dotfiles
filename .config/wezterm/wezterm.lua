-- A straight port of ../kitty/kitty.conf. Change both together.
local wezterm = require("wezterm")
local act = wezterm.action

local config = wezterm.config_builder()

local is_mac = wezterm.target_triple:find("darwin") ~= nil

-- --- Performance ---
config.max_fps = 120

-- --- Font ---
config.font = wezterm.font("FiraCode Nerd Font Mono")
config.font_size = is_mac and 16.0 or 13.0
config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }

-- --- Window ---
config.window_background_opacity = 1
config.window_padding = { left = "4pt", right = "4pt", top = "4pt", bottom = "4pt" }
config.window_decorations = "RESIZE"
-- kitty does not dim unfocused splits; wezterm does by default.
config.inactive_pane_hsb = { saturation = 1.0, brightness = 1.0 }

-- --- Bell ---
config.audible_bell = "Disabled"

-- --- Colours (Catppuccin Mocha, on mantle rather than base) ---
config.colors = {
  foreground = "#cdd6f4",
  background = "#181825",
  selection_fg = "#1e1e2e",
  selection_bg = "#f5e0dc",
  cursor_bg = "#f5e0dc",
  cursor_border = "#f5e0dc",
  cursor_fg = "#1e1e2e",
  split = "#6c7086",
  ansi = { "#45475a", "#f38ba8", "#a6e3a1", "#f9e2af", "#89b4fa", "#f5c2e7", "#94e2d5", "#bac2de" },
  brights = { "#585b70", "#f38ba8", "#a6e3a1", "#f9e2af", "#89b4fa", "#f5c2e7", "#94e2d5", "#a6adc8" },
  tab_bar = {
    background = "#181825",
    active_tab = { bg_color = "#cba6f7", fg_color = "#11111b" },
    inactive_tab = { bg_color = "#181825", fg_color = "#cdd6f4" },
    inactive_tab_hover = { bg_color = "#181825", fg_color = "#cdd6f4" },
  },
}

-- --- Tab bar: kitty's slanted powerline style ---
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.hide_tab_bar_if_only_one_tab = true
config.show_new_tab_button_in_tab_bar = false
config.tab_max_width = 32

local SLANT_LEFT = wezterm.nerdfonts.ple_lower_right_triangle
local SLANT_RIGHT = wezterm.nerdfonts.ple_upper_left_triangle

wezterm.on("format-tab-title", function(tab, _, _, cfg)
  local bar = cfg.colors.tab_bar
  local style = tab.is_active and bar.active_tab or bar.inactive_tab

  -- kitty: {title}{' :N:' if num_windows > 1}
  local title = tab.tab_title ~= "" and tab.tab_title or tab.active_pane.title
  local panes = #tab.panes
  if panes > 1 then
    title = title .. " :" .. panes .. ":"
  end

  -- The first tab runs square to the window edge, as kitty draws it.
  local left = tab.tab_index == 0 and "" or SLANT_LEFT

  return {
    { Background = { Color = bar.background } },
    { Foreground = { Color = style.bg_color } },
    { Text = left },
    { Background = { Color = style.bg_color } },
    { Foreground = { Color = style.fg_color } },
    { Text = " " .. title .. " " },
    { Background = { Color = bar.background } },
    { Foreground = { Color = style.bg_color } },
    { Text = SLANT_RIGHT },
  }
end)

-- --- Keys ---
-- SUPER+1..8, SUPER+T and SUPER+SHIFT+[ / ] are wezterm defaults already.
-- These are the ones where kitty's behaviour differs.
config.keys = {
  -- wezterm's default SUPER+9 is the LAST tab; kitty's goto_tab 9 is the ninth.
  { key = "9", mods = "SUPER", action = act.ActivateTab(8) },
  -- Close without asking.
  { key = "w", mods = "SUPER", action = act.CloseCurrentTab({ confirm = false }) },
}

if is_mac then
  config.send_composed_key_when_left_alt_is_pressed = true
  -- alt+q quits, matching Hyprland's ALT+Q. On Linux Hyprland takes it first.
  table.insert(config.keys, { key = "q", mods = "ALT", action = act.QuitApplication })
else
  -- Hyprland grabs super+w and re-sends ctrl+shift+w to terminals, so the same
  -- key can reach Firefox as ctrl+w. Has to close a tab, as kitty's does.
  table.insert(config.keys, { key = "w", mods = "CTRL|SHIFT", action = act.CloseCurrentTab({ confirm = false }) })
end

return config
