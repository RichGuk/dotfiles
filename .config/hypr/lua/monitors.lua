
------------------
---- MONITORS ----
------------------

-- Scales must be k/120 where k divides gcd(w*120, h*120); anything else is
-- silently ignored. 3840x2160 -> 1.5, 5120x2880 -> 2, 2256x1504 -> 1.6.

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

-- Per-output scales written by the bar's display popout; do not edit by hand.
local stateFile = (os.getenv("XDG_STATE_HOME")
                   or (os.getenv("HOME") .. "/.local/state"))
                  .. "/hyprland-shell/monitors.lua"

-- pcall: the file is missing on first run, or may be half-written.
local ok, overrides = pcall(dofile, stateFile)

if ok and type(overrides) == "table" then
    for output, override in pairs(overrides) do
        hl.monitor({
            output   = output,
            mode     = "preferred",
            position = "auto",
            scale    = override.scale,
        })
    end
end

-- Hand-written overrides go here, after the generated ones so they win.

-- Dell G3223Q. Mode is explicit because `preferred` gives 60Hz; 120Hz needs
-- amdgpu.dcfeaturemask=0x402 (HDMI 2.1 FRL) on the kernel line.
-- Position is explicit: once any output is fixed, `auto` re-lays the rest.
hl.monitor({
    output   = "HDMI-A-1",
    mode     = "3840x2160@120",
    position = "0x0",
    scale    = 1.5,
})

-- Second monitor, centred below the Dell. Positions are LOGICAL:
-- x = (2560 - 1920) / 2, y = Dell's logical height. Change a scale, redo this.
hl.monitor({
    output   = "DP-2",
    mode     = "1920x1080@60",
    position = "320x1440",
    scale    = 1,
})

-- `default` is needed, or DP-2 comes back on the lowest free workspace.
hl.workspace_rule({ workspace = 9,  monitor = "DP-2", default = true })
hl.workspace_rule({ workspace = 10, monitor = "DP-2" })

-- Unpinned workspaces are created on whichever monitor has focus.
for ws = 1, 8 do
    hl.workspace_rule({ workspace = ws, monitor = "HDMI-A-1" })
end

-- Do not set GDK_SCALE / GDK_DPI_SCALE: they fight Wayland's own scaling.

