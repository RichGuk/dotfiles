local settings = require("hypr.lua.settings")

---------------------
---- KEYBINDINGS ----
---------------------

-- ALT is the main modifier, mirroring the Mac. Workspaces are on caps
-- (ctrl+alt+super via keyd).

---- Programs ----------------------------------------------------------------

hl.bind("ALT + Return", hl.dsp.exec_cmd(settings.terminal), { description = "Terminal" })
hl.bind("SUPER + Return", hl.dsp.exec_cmd(settings.terminal), { description = "Terminal" })

hl.bind("ALT + up", hl.dsp.exec_cmd(settings.browser),
        { description = "Browser" })
hl.bind("ALT + left", hl.dsp.exec_cmd(settings.browserAlt),
        { description = "Second browser" })
hl.bind("ALT + down", hl.dsp.exec_cmd(settings.fileManager .. " " .. os.getenv("HOME")),
        { description = "Files" })

-- Needs the `vicinae server` from autostart.lua; toggle on a dead server does
-- nothing. Check with `vicinae ping`.
hl.bind("ALT + SPACE", hl.dsp.exec_cmd("vicinae toggle"), { description = "Launcher" })
hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("vicinae toggle"), { description = "Launcher" })

hl.bind("SUPER + SHIFT + P", hl.dsp.exec_cmd("pkill hyprpicker || hyprpicker -a"),
        { description = "Colour picker" })

---- Windows -----------------------------------------------------------------

-- SUPER+W (close tab) is under "Close tab" below.
hl.bind("ALT + Q", hl.dsp.window.close(), { description = "Close window" })

hl.bind("ALT + F", function()
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
    hl.dispatch(hl.dsp.window.center())
end, { description = "Toggle floating and centre" })

-- Mode 1 keeps the tiling tree; mode 0 is real fullscreen.
hl.bind("ALT + M", hl.dsp.window.fullscreen({ mode = 1 }), { description = "Maximize" })
hl.bind("SUPER + SHIFT + M", hl.dsp.window.fullscreen({ mode = 0 }), { description = "Fullscreen" })

-- Hyprland only pins floating windows, so a tiled one is floated first and
-- re-tiled on unpin; dialogs already floating stay floating. Keyed by stable_id.
local floatedForPin = {}

hl.bind("SUPER + P", function()
    local win = hl.get_active_window()
    if not win then return end

    if win.pinned then
        hl.dispatch(hl.dsp.window.pin())
        if floatedForPin[win.stable_id] then
            hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
            floatedForPin[win.stable_id] = nil
        end
    else
        if not win.floating then
            hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
            floatedForPin[win.stable_id] = true
        end
        hl.dispatch(hl.dsp.window.pin())
    end
end, { description = "Toggle window pinned to all workspaces" })

---- Tiling ------------------------------------------------------------------

hl.bind("ALT + slash", hl.dsp.layout("togglesplit"), { description = "Toggle split direction" })
hl.bind("ALT + SHIFT + slash", hl.dsp.layout("swapsplit"), { description = "Swap split" })
hl.bind("ALT + SHIFT + M", hl.dsp.layout("movetoroot active"), { description = "Promote to root split" })

-- Lone window in a centred 1:1 box; [0, 0] is unconstrained.
local narrowSingleWindow = false

hl.bind("ALT + SHIFT + A", function()
    narrowSingleWindow = not narrowSingleWindow
    hl.config({
        layout = {
            single_window_aspect_ratio = narrowSingleWindow and { 1, 1 } or { 0, 0 },
        },
    })
end, { description = "Toggle narrow single-window layout" })

-- Preselect where the next window opens.
for key, dir in pairs({ h = "l", j = "d", k = "u", l = "r" }) do
    hl.bind("ALT + CTRL + " .. key, hl.dsp.layout("preselect " .. dir),
            { description = "Preselect next window " .. dir })
end

---- Focus and movement -----------------------------------------------------

local directions = { h = "left", j = "down", k = "up", l = "right" }

for key, dir in pairs(directions) do
    hl.bind("ALT + " .. key, hl.dsp.focus({ direction = dir }),
            { description = "Focus " .. dir })
    hl.bind("SUPER + " .. key, hl.dsp.focus({ direction = dir }),
            { description = "Focus " .. dir })

    -- swap, not move: move re-inserts into the tree and reshuffles the layout.
    hl.bind("ALT + SHIFT + " .. key, hl.dsp.window.swap({ direction = dir }),
            { description = "Swap window " .. dir })
    hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.swap({ direction = dir }),
            { description = "Swap window " .. dir })
end

-- Cycle windows on the active workspace, raising as we go.
hl.bind("ALT + Tab", function()
    hl.dispatch(hl.dsp.window.cycle_next())
    hl.dispatch(hl.dsp.window.bring_to_top())
end, { description = "Cycle to next window" })

hl.bind("ALT + SHIFT + Tab", function()
    hl.dispatch(hl.dsp.window.cycle_next({ prev = true }))
    hl.dispatch(hl.dsp.window.bring_to_top())
end, { description = "Cycle to previous window" })

---- Resize ------------------------------------------------------------------

-- The - and = keys, by keycode so the layout can't move them.
hl.bind("ALT + code:20", hl.dsp.window.resize({ x = -100, y = 0, relative = true }),
        { description = "Shrink window horizontally" })
hl.bind("ALT + code:21", hl.dsp.window.resize({ x = 100, y = 0, relative = true }),
        { description = "Grow window horizontally" })
hl.bind("ALT + SHIFT + code:20", hl.dsp.window.resize({ x = 0, y = -100, relative = true }),
        { description = "Shrink window vertically" })
hl.bind("ALT + SHIFT + code:21", hl.dsp.window.resize({ x = 0, y = 100, relative = true }),
        { description = "Grow window vertically" })

hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true, description = "Move window" })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true, description = "Resize window" })

---- Workspaces --------------------------------------------------------------

-- caps emits ctrl+alt+super via keyd, so caps+N focuses and caps+shift+N moves.
for i, key in ipairs(settings.workspaceKeys) do
    hl.bind("CTRL + ALT + SUPER + " .. key, hl.dsp.focus({ workspace = i }),
            { description = "Focus workspace " .. i })
    hl.bind("CTRL + ALT + SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }),
            { description = "Move window to workspace " .. i })
end

-- Tab between workspaces on this monitor.
hl.bind("SUPER + Tab", hl.dsp.focus({ workspace = "m+1" }), { description = "Next workspace" })
hl.bind("SUPER + SHIFT + Tab", hl.dsp.focus({ workspace = "m-1" }), { description = "Previous workspace" })

---- Lock -------------------------------------------------------------------

-- The lock is the shell's (ext-session-lock), not hyprlock.
hl.bind("SUPER + CTRL + L", hl.dsp.exec_cmd("qs ipc call lock lock"),
        { description = "Lock the session" })

---- Universal clipboard -----------------------------------------------------

-- SUPER+C/V/X copy, paste and cut everywhere.
--
-- send_key_state, not wtype/ydotool: a virtual keyboard merges the held SUPER
-- into the chord. Down and up must be separate dispatches 50ms apart, or the
-- key can stick: https://github.com/hyprwm/Hyprland/discussions/14099
--
-- Terminals get CTRL+SHIFT+C/V: CTRL+C is SIGINT. Not SHIFT+Insert, which kitty
-- reads as paste-from-PRIMARY.

local function sendKeyOnce(mods, key)
    return function()
        hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))
        hl.timer(function()
            hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
        end, { timeout = 50, type = "oneshot" })
    end
end

-- Matched on class, as hl.get_active_window() reports it.
local terminalClasses = {
    kitty = true,
    foot = true,
    footclient = true,
    Alacritty = true,
    ["com.mitchellh.ghostty"] = true,
    ["org.wezfurlong.wezterm"] = true,
}

local function activeIsTerminal()
    local w = hl.get_active_window()
    if not w then return false end
    return terminalClasses[w.class] == true
end

local function translatedKey(mods, key, termMods, termKey)
    return function()
        if activeIsTerminal() then
            sendKeyOnce(termMods, termKey)()
        else
            sendKeyOnce(mods, key)()
        end
    end
end

hl.bind("SUPER + C", translatedKey("CTRL", "C", "CTRL SHIFT", "C"),
        { description = "Copy" })
hl.bind("SUPER + V", translatedKey("CTRL", "V", "CTRL SHIFT", "V"),
        { description = "Paste" })
hl.bind("SUPER + X", sendKeyOnce("CTRL", "X"), { description = "Cut" })

---- Close tab ---------------------------------------------------------------

-- SUPER+W closes a tab, like cmd+W. Terminals get CTRL+SHIFT+W, which kitty.conf
-- must map to `close_tab` (its default is close_window); keep the two in step.
hl.bind("SUPER + W", translatedKey("CTRL", "W", "CTRL SHIFT", "W"),
        { description = "Close tab" })

---- Wallpaper --------------------------------------------------------------

hl.bind("SUPER + SHIFT + W", hl.dsp.exec_cmd("qs ipc call wallpaper toggle"),
        { description = "Wallpaper picker" })

---- Screenshots -------------------------------------------------------------

-- macOS digits: 2 window, 3 whole screen, 4 region, 5 record.
-- Keycodes, not "2"/"3"/"4": with SHIFT held the digit row yields dollar etc.,
-- so a keysym bind never matches.
local screenshots = {
    { key = "code:11", mode = "window", what = "window" },       -- 2
    { key = "code:12", mode = "output", what = "whole screen" }, -- 3
    { key = "code:13", mode = "region", what = "region" },       -- 4
}

for _, shot in ipairs(screenshots) do
    hl.bind("SUPER + SHIFT + " .. shot.key,
            hl.dsp.exec_cmd(settings.scripts .. "hypr-screenshot " .. shot.mode),
            { description = "Screenshot " .. shot.what })
end

-- DP-2 can come back dark after DPMS or suspend; the script re-adds it.
hl.bind("SUPER + SHIFT + D", hl.dsp.exec_cmd(settings.scripts .. "hypr-wake-displays"),
        { description = "Re-detect displays" })

-- Opens the shell's chooser, or stops a running recording.
hl.bind("SUPER + SHIFT + code:14",
        hl.dsp.exec_cmd(settings.scripts .. "hypr-screenrecord menu"),
        { description = "Screen recording (toggle)" })

---- Session -----------------------------------------------------------------

hl.bind("SUPER + CTRL + BackSpace", hl.dsp.exit(), { description = "Exit Hyprland" })

---- Lid ---------------------------------------------------------------------

-- Clamshell: lid closed disables the built-in panel, but only if an external
-- is attached. `locked = true` so it fires while locked.
-- "Lid Switch" is the ACPI driver's device name; check `hyprctl devices`.
hl.bind("switch:on:Lid Switch", function()
    local internal = settings.internalOutput()
    if internal and settings.hasExternalMonitor() then
        hl.monitor({ output = internal, disabled = true })
    end
end, { locked = true, description = "Lid closed" })

hl.bind("switch:off:Lid Switch", function()
    for _, pattern in ipairs(settings.internalOutputPatterns) do
        for _, monitor in ipairs(hl.get_monitors()) do
            if monitor.name:match(pattern) then
                hl.monitor({
                    output   = monitor.name,
                    mode     = "preferred",
                    position = "auto",
                    scale    = "auto",
                })
                return
            end
        end
    end
end, { locked = true, description = "Lid opened" })

---- Media keys --------------------------------------------------------------

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
        { locked = true, repeating = true, description = "Volume up" })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
        { locked = true, repeating = true, description = "Volume down" })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
        { locked = true, description = "Mute" })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
        { locked = true, description = "Mute microphone" })

hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true, description = "Next track" })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true, description = "Previous track" })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Play/pause" })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true, description = "Play/pause" })

