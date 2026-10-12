-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

local settings = require("hypr.lua.settings")

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_STYLE_OVERRIDE", "kvantum")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("OZONE_PLATFORM", "wayland")
hl.env("XDG_SESSION_TYPE", "wayland")

-- Needed for screen sharing.
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Must be absolute: env values are not tilde-expanded.
hl.env("XCOMPOSEFILE", os.getenv("HOME") .. "/.XCompose")

-- Read by the shell as Quickshell.env("TERMINAL"). hl.env only reaches
-- processes spawned afterwards.
hl.env("TERMINAL", settings.terminal)

hl.config({
    xwayland = { force_zero_scaling = true },
    ecosystem = { no_update_news = true },
})

