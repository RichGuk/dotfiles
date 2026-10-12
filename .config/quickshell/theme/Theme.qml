pragma Singleton

// Every visual token in one place. Imported as `import qs.theme`.

import QtQuick
import Quickshell

Singleton {
    // ------------------------------------------------------------------
    // Colour — Catppuccin Mocha. Must match config/hypr/lua/looknfeel.lua.
    // Mauve means "where you are" / focused window; keep it off popout borders.
    // ------------------------------------------------------------------
    readonly property color crust:     "#11111b"  // bar background
    readonly property color base:      "#1e1e2e"  // cards on a panel
    readonly property color surface0:  "#313244"  // popout border
    readonly property color surface1:  "#45475a"  // separators
    readonly property color surface2:  "#585b70"  // a stronger border, if wanted
    readonly property color overlay0:  "#6c7086"  // empty workspaces, dimmed text
    readonly property color subtext0:  "#a6adc8"  // module icons
    readonly property color subtext1:  "#bac2de"  // occupied workspaces
    readonly property color text:      "#cdd6f4"  // brightest — launcher, titles
    readonly property color attention: "#f38ba8"  // urgent only (Mocha red)
    readonly property color warning:   "#f9e2af"  // Mocha yellow
    readonly property color mauve:     "#cba6f7"  // accent — ws ball, window border

    // ------------------------------------------------------------------
    // The bar reads at one brightness: everything uses barText. barDim means a
    // device that is off (muted, powered down, empty workspace), not a rank.
    // ------------------------------------------------------------------
    readonly property color barText: text
    readonly property color barDim:  overlay0

    // ------------------------------------------------------------------
    // Bar geometry
    // ------------------------------------------------------------------
    readonly property int barHeight:     32
    readonly property int edgeMargin:    10
    // Keep wider than the gap inside a module, or modules blur together.
    readonly property int moduleSpacing: 14

    // Between groups (now playing / tray / system).
    readonly property int groupSpacing:  32

    // ------------------------------------------------------------------
    // Tray
    // ------------------------------------------------------------------
    readonly property int trayIconSize:    16
    readonly property int trayItemSpacing: 12

    readonly property int trayDrawerDuration: 240

    // ------------------------------------------------------------------
    // Workspaces. Keep wsIndicatorSize EVEN: the radius is an int, and an odd
    // size truncates it so the ball gets flat sides.
    // ------------------------------------------------------------------
    readonly property int wsItemSize:        24
    readonly property int wsSpacing:         6
    readonly property int wsIndicatorSize:   10
    readonly property int wsIndicatorRadius: wsIndicatorSize / 2

    readonly property int wsSlideDuration: 220

    // ------------------------------------------------------------------
    // Type — one size across the bar. "Propo" is proportional, so the clock
    // shifts slightly as digits change; the Mono cut would not.
    // ------------------------------------------------------------------
    readonly property string fontFamily: "JetBrainsMono Nerd Font Propo"
    readonly property int fontSize:      15

    readonly property int popoutTitleSize: 17
    readonly property int popoutBodySize:  13

    // ------------------------------------------------------------------
    // Motion
    // ------------------------------------------------------------------
    readonly property int animDuration: 150

    readonly property int popoutAnimDuration: 180
    readonly property int animEasing:   Easing.OutQuint

    // ------------------------------------------------------------------
    // Popout surfaces. The panel takes the bar's colour; cards give contrast.
    // ------------------------------------------------------------------
    readonly property color popoutBg:   crust
    readonly property color popoutCard: base

    // Not the accent: that turns the flared corners into brackets.
    readonly property color popoutEdge: surface0
    readonly property int popoutBorder: 1

    // How far the top corners curve outward into the bar (see Popout.qml).
    readonly property int popoutFlare: 12

    // The popout window is larger than the panel by this on the sides and
    // bottom, since a window clips its own contents.
    readonly property int   popoutShadowMargin:  24

    // Edge-anchored popouts run flush to the screen edge with a square corner;
    // false uses popoutEdgeGap instead.
    readonly property bool popoutEdgeFlush: true
    readonly property int  popoutEdgeGap:   4
    readonly property real  popoutShadowBlur:    1.0   // 0..1 of blurMax
    readonly property real  popoutShadowOpacity: 0.7
    readonly property int   popoutShadowOffsetY: 6
    readonly property color popoutShadowColor:   "#000000"

    // MPRIS source badge, top-right of the media popout.
    readonly property int popoutBadgeSize: 20

    // Transport controls. transportHit pads the click area beyond the glyph.
    readonly property int popoutTransportSize:    24
    readonly property int popoutTransportSpacing: 20
    readonly property int popoutTransportHit:     8

    // Caps the bar's now-playing label: the module is centred, so a long title
    // would shunt the clock and tray around.
    readonly property int barMediaMaxWidth: 380

    readonly property int popoutRowHeight:   32
    readonly property int popoutTodayBarW:   3
    readonly property int popoutTodayBarH:   16

    readonly property int moduleIndicatorWidth:  14
    readonly property int moduleIndicatorHeight: 2

    readonly property int sliderTrackHeight: 6
    readonly property int sliderHitHeight:  18
    readonly property int sliderKnobSize:   12

    readonly property int calCellSize:   34
    readonly property int calMarkerSize: 26

    // Bounds for the media popout, which sizes itself from its title.
    readonly property int popoutMinWidth: 340
    readonly property int popoutMaxWidth: 680

    // ------------------------------------------------------------------
    // Toasts
    // ------------------------------------------------------------------
    readonly property int toastWidth:     360
    readonly property int toastPadding:   14
    readonly property int toastSpacing:   10
    readonly property int toastRadius:    14
    readonly property int toastAccent:    3     // the urgency stripe
    readonly property int toastImageSize: 40

    readonly property int toastGap: 10

    readonly property int toastAnimDuration: 260

    readonly property int popoutRadius:     14
    readonly property int popoutCardRadius: 10
    readonly property int popoutPadding:    18
    readonly property int popoutGap:        16

    // ------------------------------------------------------------------
    // Glyphs, as codepoints -- never paste literal glyph characters, they get
    // dropped on the way to disk. Verify a codepoint by rendering it; names lie.
    // ------------------------------------------------------------------
    readonly property var glyphs: ({
        arch:         0xE732,   // launcher

        weather:      0xF0F31,  // md-weather-partly-cloudy — the bar module

        wxSunny:      0xF0599,
        wxPartly:     0xF0F31,
        wxCloudy:     0xF0590,
        wxRain:       0xF0597,
        wxPouring:    0xF0596,
        wxSnow:       0xF0598,
        wxStorm:      0xF0593,
        wxFog:        0xF0591,
        wxWind:       0xF059D,
        wxHail:       0xF0592,
        wxNight:      0xF0594,
        wxDroplet:    0xF058C,  // md-water — rain probability

        chevronDown:  0xF0140,
        chevronLeft:  0xF0141,
        chevronRight: 0xF0142,
        chevronUp:    0xF0143,
        search:       0xF0349,  // md-magnify
        pin:          0xF0403,  // md-map-marker
        close:        0xF0156,  // md-close
        calendar:     0xF00ED,  // md-calendar
        clock:        0xF0954,  // md-clock-outline
        music:        0xF075A,  // md-music — also the no-artwork fallback

        prev:         0xF04AE,  // md-skip-previous
        pause:        0xF03E4,  // md-pause
        play:         0xF040A,  // md-play
        next:         0xF04AD,  // md-skip-next

        steam:        0xF04D3,  // md-steam
        apps:         0xF003B,  // md-apps

        display:      0xF0379,  // md-monitor — display / scaling
        displays:     0xF037A,  // md-monitor-multiple — shown when docked

        // Rendered: crop draws corner marks, window two overlapping rectangles.
        crop:         0xF019E,  // md-crop — record an area
        window:       0xF05B2,  // md-window-restore — record a window

        coffee:       0xF0176,  // md-coffee — keep awake. Rendered: a cup.
        volumeLow:    0xF026,   // fa-volume-down
        volumeMed:    0xF027,
        volume:       0xF028,   // fa-volume-up
        mic:          0xF036C,  // md-microphone
        micOff:       0xF036D,  // md-microphone-off
        speaker:      0xF04C3,  // md-speaker — output device rows
        volumeMuted:  0xF075F,  // md-volume-off
        network:      0xF0002,  // md-ethernet
        networkDown:  0xF05AA,
        wifi:         0xF0928,

        // wifi4 is the same codepoint as `wifi`.
        wifi1:        0xF091F,
        wifi2:        0xF0922,
        wifi3:        0xF0925,
        wifi4:        0xF0928,
        wifiAlert:    0xF092B,  // wifi with "!" — associated, no internet
        wifiOff:      0xF092D,

        lan:          0xF0317,  // md-lan — network topology, used for wired
        lock:         0xF033E,  // secured network
        shieldLock:   0xF099D,  // md-shield-lock — WireGuard
        earth:        0xF01E7,  // md-earth — public IP
        ipNetwork:    0xF0A60,  // "IP" over a node — the address section
        speedometer:  0xF04C5,  // md-speedometer — latency
        transfer:     0xF04E1,  // the horizontal arrows — packet loss
        refresh:      0xF0450,  // md-refresh — rescan
        alert:        0xF0026,  // md-alert
        check:        0xF012C,  // md-check

        power:        0xF0425,  // md-power — the power button
        restart:      0xF0709,  // md-restart — circular arrow
        logout:       0xF0343,  // md-logout — arrow out of a door
        sleep:        0xF0904,  // md-weather-night — crescent moon
        hibernate:    0xF0717,  // md-snowflake — the conventional one

        updates:      0xF0BAF,  // md-pac-man
        package:      0xF03D6,  // md-package-variant-closed — an open box

        bell:         0xF009A,
        bellOff:      0xF009B,  // do not disturb
        bellOutline:  0xF009C,
        broom:        0xF00E2,  // clear all; a cross reads as "close panel"
        alertCircle:  0xF002A,  // critical urgency
        infoCircle:   0xF02FD,

        // Matched pair that swap on hover: they share a bounding circle. md-check and
        // md-close do not, and the swap looks like the icon grew.
        checkCircle:  0xF05E1,  // md-check-circle-outline — saved network
        closeCircle:  0xF015A,  // md-close-circle-outline — forget it

        bluetooth:    0xF294,   // fa-bluetooth
        bluetoothOff: 0xF00B2,
        bluetoothOn:  0xF00B0,  // md-bluetooth-connect — radio on, nothing paired

        // BlueZ device classes. md-cellphone, because U+F03F2 draws a desk handset.
        cellphone:    0xF011C,
        laptop:       0xF0322,
        printer:      0xF042A,
        tablet:       0xF04F6,
        battery:      0xF0079,
        batteryFull:  0xF0085,

        batteryAlert: 0xF0083,  // battery with "!" — critically low
        batteryOff:   0xF125D,  // struck through — no battery present
        powerPlug:    0xF06A5,  // on mains
        leaf:         0xF032A,  // power-saver profile
        scaleBalance: 0xF05D1,  // balanced profile
        heart:        0xF02D1,  // battery health

        // Peripherals that carry their own battery.
        mouse:        0xF037D,
        keyboard:     0xF030C,
        headset:      0xF02CB,
        gamepad:      0xF0297,
        phone:        0xF03F2
    })

    // ------------------------------------------------------------------
    // Battery ramps, ten steps each.
    // ------------------------------------------------------------------
    readonly property var batteryRamp: [
        0xF007A, 0xF007B, 0xF007C, 0xF007D, 0xF007E,
        0xF007F, 0xF0080, 0xF0081, 0xF0082, 0xF0079
    ]

    readonly property var batteryChargingRamp: [
        0xF089C, 0xF0086, 0xF0087, 0xF0088, 0xF089D,
        0xF0089, 0xF089E, 0xF008A, 0xF008B, 0xF0085
    ]

    // Floor to the ten below: only a true 100% draws the full glyph.
    function batteryGlyph(percent, charging) {
        const ramp = charging ? batteryChargingRamp : batteryRamp;
        const i = Math.max(0, Math.min(ramp.length - 1,
                                       Math.floor(percent / 10)));
        return String.fromCodePoint(ramp[i]);
    }

    readonly property int batteryWarnAt: 20
    readonly property int batteryCriticalAt: 10

    // Pending-updates colour thresholds.
    readonly property int updatesWarnAt: 10
    readonly property int updatesUrgentAt: 30

    function updatesColour(count) {
        if (count >= updatesUrgentAt) return attention;
        if (count >= updatesWarnAt) return warning;
        return barText;
    }

    // Warns with the name instead of a bare RangeError from fromCodePoint.
    function glyph(name) {
        const cp = glyphs[name];
        if (cp === undefined) {
            console.warn("Theme: no glyph named '" + name + "'");
            return "?";
        }
        return String.fromCodePoint(cp);
    }
}
