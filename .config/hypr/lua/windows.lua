--------------------
---- WORKSPACES ----
--------------------

-- Single tiled window: no gaps or border. `w[t1]`, not `w[tv1]` or `f[1]`,
-- which count only visible windows and so trigger when one of two is maximised.
for _, ws in ipairs({ "w[t1]" }) do
    hl.workspace_rule({
        workspace   = ws,
        gaps_in     = 0,
        gaps_out    = 0,
        no_border   = true,
        no_rounding = true,
    })
end

----------------------
---- WINDOW RULES ----
----------------------

hl.window_rule({
    -- Ignore maximize requests from everything.
    name  = "suppress-maximize",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    -- Fix some dragging issues with XWayland.
    name  = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true,
              fullscreen = false, pin = false },
    no_focus = true,
})

hl.window_rule({
    name  = "no-screenshare-bitwarden",
    match = { class = "^(Bitwarden)$" },
    no_screen_share = true,
})

-- Scroll faster in the terminal.
hl.window_rule({
    name  = "kitty-scroll",
    match = { class = "kitty" },
    scroll_touchpad = 1.5,
})

---- Browsers ----------------------------------------------------------------

-- Rule opacities multiply, and "1 1 override" is a no-op in the Lua API, so a
-- catch-all opacity cannot be undone per app.
hl.window_rule({
    name  = "tag-chromium",
    match = { class = "([cC]hrom(e|ium)|[bB]rave-browser|Microsoft-edge|Vivaldi-stable)" },
    tag   = "+chromium-based-browser",
})

-- Force chromium-based browsers to tile, working around the --app bug.
hl.window_rule({
    name  = "tile-chromium",
    match = { tag = "chromium-based-browser" },
    tile  = true,
})

---- Floating windows --------------------------------------------------------

hl.window_rule({
    name  = "tag-floating-apps",
    match = { class = "(blueberry.py|Impala|Wiremix|org.gnome.NautilusPreviewer|com.gabm.satty|About|TUI.float)" },
    tag   = "+floating-window",
})

-- File dialogs, which should never tile.
hl.window_rule({
    name  = "tag-floating-dialogs",
    match = { class = "(xdg-desktop-portal-gtk|sublime_text|DesktopEditors|org.gnome.Nautilus)",
              title = "^(Open.*Files?|Open Folder|Save.*Files?|Save.*As|Save|All Files)" },
    tag   = "+floating-window",
})

hl.window_rule({
    name   = "floating-window",
    match  = { tag = "floating-window" },
    float  = true,
    center = true,
    size   = "800 600",
})

---- Picture-in-Picture ------------------------------------------------------

-- `pin` shows it on every workspace. No `size`: the browser remembers its own.
hl.window_rule({
    name              = "picture-in-picture",
    match             = { class = "(firefox|[cC]hrom(e|ium)|[bB]rave-browser|Vivaldi-stable)",
                          title = "^Picture[- ]in[- ]Picture$" },
    float             = true,
    pin               = true,
    keep_aspect_ratio = true,
    no_initial_focus  = true,
    move              = "100%-w-20 100%-h-20",
})

---- Layers ------------------------------------------------------------------

-- Remove the 1px border around hyprshot screenshots.
hl.layer_rule({
    name    = "no-anim-selection",
    match   = { namespace = "selection" },
    no_anim = true,
})

