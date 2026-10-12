local settings = require("hypr.lua.settings")

-------------------
---- AUTOSTART ----
-------------------

-- Started by Hyprland so they inherit HYPRLAND_INSTANCE_SIGNATURE and
-- WAYLAND_DISPLAY. Each entry is skipped if its binary is not installed.

local autostart = {
    "qs",

    "hypridle",

    -- Not on PATH, hence absolute.
    "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1",

    "wl-clip-persist --clipboard regular",

    -- The launcher binds only send `vicinae toggle`; they need this running.
    -- `--replace` so a Hyprland restart does not leave the old server on the socket.
    "vicinae server --replace",
}

hl.on("hyprland.start", function()
    for _, entry in ipairs(autostart) do
        local binary = entry:match("^(%S+)")
        if settings.cmdPresent(binary) then
            hl.exec_cmd(entry)
        end
    end
end)
