-- Hyprland config entry point; the content is in lua/.
-- API reference: /usr/share/hypr/stubs/hl.meta.lua and /usr/share/hypr/hyprland.lua.

-- Hyprland does not put ~/.config on the Lua module path.
package.path = os.getenv("HOME") .. "/.config/?.lua;" .. package.path

require("hypr.lua.monitors")
require("hypr.lua.envs")
require("hypr.lua.looknfeel")
require("hypr.lua.input")
require("hypr.lua.windows")
require("hypr.lua.bindings")
require("hypr.lua.autostart")
