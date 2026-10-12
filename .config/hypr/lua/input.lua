---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "us",

        -- For one keysym: sterling on level 3 of the 3 key. Levels 1-2 are
        -- identical to plain us. Pairs with lv3:ralt_switch and keyd's
        -- `3 = G-3`; compose cannot do £ (GTK4 and Chromium ignore it).
        kb_variant = "mac",

        -- Compose on right ctrl because keyd claims right alt for HYPER.
        -- lv3:ralt_switch is reachable only via keyd's emitted right alt.
        kb_options = "compose:rctrl,lv3:ralt_switch",

        follow_mouse = 1,

        repeat_rate  = 30,
        repeat_delay = 300,

        -- 0 is libinput's default speed (an offset, not "slow"); flat gives 1:1.
        sensitivity   = 0,
        accel_profile = "flat",
        scroll_factor = 1,

        touchpad = {
            natural_scroll = false,
            scroll_factor  = 0.5,
        },
    },
})

