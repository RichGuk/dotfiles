-- Values shared by more than one module.

local M = {}

M.terminal = "kitty"

-- Built from HOME, not "$HOME/...", because exec_cmd may not go through a shell.
M.scripts = os.getenv("HOME") .. "/.config/hypr/scripts/"
M.browser = "firefox"

M.browserAlt  = "chromium"
M.fileManager = "nautilus"

-- Workspaces 1-8 on the digit row, 9 and 10 on q and w, matching the Mac.
-- Keycodes rather than keysyms so a layout change can't move them.
-- 9 and 10 are pinned to the second monitor in monitors.lua.
M.workspaceKeys = { "code:10", "code:11", "code:12", "code:13",
                    "code:14", "code:15", "code:16", "code:17",
                    "q", "w" }

-- DRM connector prefixes for a built-in panel; externals are DP-*, HDMI-A-*.
M.internalOutputPatterns = { "^eDP", "^LVDS", "^DSI" }

-- The internal panel's name, or nil (lid shut, or a desktop).
function M.internalOutput()
    for _, monitor in ipairs(hl.get_monitors()) do
        for _, pattern in ipairs(M.internalOutputPatterns) do
            if monitor.name:match(pattern) then
                return monitor.name
            end
        end
    end
    return nil
end

function M.hasExternalMonitor()
    local internal = M.internalOutput()
    for _, monitor in ipairs(hl.get_monitors()) do
        if monitor.name ~= internal then
            return true
        end
    end
    return false
end

-- Checks the filesystem rather than shelling out: Hyprland reaps its own
-- children, so os.execute() cannot report an exit status reliably.
function M.cmdPresent(command)
    if command:find("/", 1, true) then
        local file = io.open(command, "r")
        if file then file:close(); return true end
        return false
    end

    local path = os.getenv("PATH") or "/usr/local/bin:/usr/bin"
    for dir in (path .. ":"):gmatch("([^:]*):") do
        if dir ~= "" then
            local file = io.open(dir .. "/" .. command, "r")
            if file then file:close(); return true end
        end
    end
    return false
end

return M
