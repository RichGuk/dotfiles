// Quickshell bar: shared state, per-screen windows, modules, popout wiring.
// Start qs through Hyprland, never from SSH (wrong session for polkit/IPC).

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick.Effects
import qs.theme
import qs.components
import qs.services
import qs.popouts

ShellRoot {
    id: root

    settings.watchFiles: true

    // ------------------------------------------------------------------
    // Which popout is open: one value, so clicking another module switches.
    // ------------------------------------------------------------------
    property string openPopout: ""

    function togglePopout(name) {
        root.openPopout = (root.openPopout === name) ? "" : name;
    }

    // Changing workspace closes whatever is open.
    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() { root.openPopout = ""; }
    }


    // UNUSED: the bar shows numbers. Kept so switching back is one line.
    // Codepoints verified by rendering; names were wrong.
    readonly property var workspaceIcons: ({
        1: 0xF120, 2: 0xE658, 3: 0xF121, 4: 0xF0B1,
        5: 0xF0EDE, 6: 0xF001, 7: 0xF04D3
    })

    // Shown always as a display decision, not Hyprland `persistent` rules, so
    // SUPER+Tab cycling is unaffected.
    readonly property int persistentWorkspaces: 8

    // 9 and 10 are reached with Q and W, so labelled by key.
    readonly property var workspaceLabels: ({ 9: "Q", 10: "W" })

    // Q and W are always shown only while a second monitor is attached.
    readonly property var secondaryWorkspaces:
        Quickshell.screens.length > 1 ? [9, 10] : []

    // Toasts: one window, on the bar's screen.
    ToastLayer {
        screen: root.barScreen
    }

    // Exactly one bar: the widest screen, unless primaryScreenName names a
    // connector (`hyprctl monitors`).
    readonly property string primaryScreenName: ""

    readonly property var barScreen: {
        const all = Quickshell.screens;
        if (!all.length) return null;

        if (root.primaryScreenName !== "") {
            const named = all.find(s => s.name === root.primaryScreenName);
            // Falls through to widest if the named display is not attached.
            if (named) return named;
        }

        return all.reduce((widest, s) => s.width > widest.width ? s : widest, all[0]);
    }

    // Must stay false while there is only one bar, or Q and W have nowhere to
    // appear. Flip it when each monitor gets its own bar.
    readonly property bool perMonitorWorkspaces: false

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // ---------------- wallpaper picker ----------------
    WallpaperPicker {}

    // ---------------- capture chooser ----------------
    CapturePicker {}

    // ---------------- session lock ----------------
    LockScreen {}

    // ---------------- wallpaper ----------------
    // Every screen, unlike the bar.
    Variants {
        model: Quickshell.screens

        // No modelData here: WallpaperLayer declares it required. Redeclaring it
        // (modelData: modelData) is a self-assignment and the surface silently
        // never appears.
        WallpaperLayer {}
    }

    Variants {
        // Variants so docking/undocking moves the bar without a restart. Other
        // screens get no PanelWindow, so nothing reserves space on them.
        model: root.barScreen ? [root.barScreen] : []

        PanelWindow {
            id: bar
            required property var modelData

            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: Theme.barHeight
            color: Theme.crust

            // An IdleInhibitor needs a window; the bar always exists.
            IdleInhibitor {
                window: bar
                enabled: Idle.keepAwake
            }

            exclusiveZone: Theme.barHeight

            // Empty bar closes whatever is open. The bar is inside the popout's focus
            // grab, so the compositor never reports these clicks as "outside".
            // FIRST child on purpose: modules stack above it and keep their clicks.
            MouseArea {
                anchors.fill: parent
                onClicked: root.openPopout = ""
            }

            // ---------------- left ----------------
            Row {
                anchors {
                    left: parent.left
                    leftMargin: Theme.edgeMargin
                    verticalCenter: parent.verticalCenter
                }
                spacing: Theme.moduleSpacing

                // Arch logo: opens the power menu.
                BarModule {
                    id: powerModule

                    popout: "power"
                    activePopout: root.openPopout
                    onActivated: root.togglePopout("power")

                    BarText {
                        text: Theme.glyph("arch")
                        color: Theme.barText
                        pixelSize: 20
                    }
                }

                // Live workspaces. One marker slides between cells so movement has direction.
                Item {
                    id: workspaces

                    height: Theme.wsItemSize
                    width: wsRow.width
                    anchors.verticalCenter: parent.verticalCenter

                    // 1..persistentWorkspaces always, plus any higher one that exists.
                    // Negative ids are special workspaces and are excluded.
                    readonly property var entries: {
                        const myMonitor = Hyprland.monitorFor(bar.screen);

                        const mine = w =>
                            !root.perMonitorWorkspaces
                            || (w.monitor && myMonitor && w.monitor.id === myMonitor.id);

                        const live = Hyprland.workspaces.values;
                        const byId = {};
                        for (const w of live) {
                            if (w.id >= 1 && mine(w)) byId[w.id] = w;
                        }

                        const ids = [];
                        for (let i = 1; i <= root.persistentWorkspaces; i++) ids.push(i);
                        for (const id of root.secondaryWorkspaces) ids.push(id);

                        for (const id of Object.keys(byId).map(Number)) {
                            if (!ids.includes(id)) ids.push(id);
                        }
                        ids.sort((a, b) => a - b);

                        return ids.map(id => {
                            const ws = byId[id] ?? null;
                            return {
                                wsId: id,
                                label: root.workspaceLabels[id] ?? String(id),
                                workspace: ws,
                                focused: ws ? ws.focused : false,
                                urgent: ws ? ws.urgent : false,
                                // "exists" is not "has windows": Hyprland keeps
                                // an empty workspace while you are on it.
                                occupied: ws ? ws.toplevels.values.length > 0 : false
                            };
                        });
                    }

                    readonly property int focusedIndex:
                        entries.findIndex(e => e.focused)

                    // The sliding ball. The focused cell hides its number.
                    Rectangle {
                        width: Theme.wsIndicatorSize
                        height: Theme.wsIndicatorSize
                        radius: Theme.wsIndicatorRadius
                        color: Theme.mauve
                        anchors.verticalCenter: parent.verticalCenter

                        // Hidden when focus is on a workspace not shown.
                        opacity: workspaces.focusedIndex >= 0 ? 1 : 0

                        x: Math.max(0, workspaces.focusedIndex)
                             * (Theme.wsItemSize + Theme.wsSpacing)
                           + (Theme.wsItemSize - Theme.wsIndicatorSize) / 2

                        Behavior on x {
                            NumberAnimation {
                                duration: Theme.wsSlideDuration
                                easing.type: Theme.animEasing
                            }
                        }

                        Behavior on opacity {
                            NumberAnimation { duration: Theme.animDuration }
                        }
                    }

                    Row {
                        id: wsRow
                        spacing: Theme.wsSpacing

                        Repeater {
                            model: workspaces.entries

                            Item {
                                required property var modelData

                                width: Theme.wsItemSize
                                height: Theme.wsItemSize

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSize

                                    // The ball stands in for the focused number.
                                    opacity: modelData.focused ? 0 : 1

                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: Theme.animDuration
                                            easing.type: Theme.animEasing
                                        }
                                    }

                                    color: modelData.urgent ? Theme.attention
                                         : modelData.occupied ? Theme.barText
                                         : Theme.barDim

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: Theme.animDuration
                                            easing.type: Theme.animEasing
                                        }
                                    }
                                }

                                // Not Hyprland.dispatch("workspace 3"): with a Lua
                                // config dispatch takes Lua. A workspace that does
                                // not exist yet has no object, so needs Lua dispatch.
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (modelData.workspace) {
                                            modelData.workspace.activate();
                                        } else {
                                            Hyprland.dispatch(
                                                `hl.dsp.focus({ workspace = ${modelData.wsId} })`
                                            );
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

            }

            // ---------------- centre ----------------
            // Now playing, on true centre.
            Item {
                id: mediaModule

                height: Theme.barHeight
                width: mediaRow.width
                anchors.centerIn: parent

                Row {
                    id: mediaRow

                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    BarText {
                        text: Media.track
                            ? Theme.glyph(Media.track.playing ? "pause" : "play")
                            : Theme.glyph("music")
                        color: Theme.barText
                    }

                    BarText {
                        // Many MPRIS sources publish no artist.
                        text: Media.track
                            ? (Media.track.artist
                                ? Media.track.artist + " - " + Media.track.title
                                : Media.track.title)
                            : "nothing playing"
                        color: Media.track ? Theme.barText : Theme.barDim

                        // Elide needs an explicit width; a self-sized Text
                        // never overflows.
                        width: Math.min(implicitWidth, Theme.barMediaMaxWidth)
                        elide: Text.ElideRight
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.togglePopout("media")
                }
            }

            // ---------------- right ----------------
            Row {
                anchors {
                    right: parent.right
                    rightMargin: Theme.edgeMargin
                    verticalCenter: parent.verticalCenter
                }
                spacing: Theme.groupSpacing

                // ---- the meeting, set apart ----
                // Its own group so groupSpacing, not moduleSpacing, separates the two text
                // modules. First, so appearing grows into empty bar and leaves weather put.
                BarModule {
                    id: meetingModule

                    visible: Meeting.hasMeeting
                    popout: "meeting"
                    activePopout: root.openPopout
                    onActivated: root.togglePopout("meeting")

                    BarText {
                        text: Theme.glyph("calendar") + " " + Meeting.label
                        // Amber once the meeting is running.
                        color: Meeting.current
                            && Meeting.current.state === "now"
                            ? Theme.warning : Theme.barText
                        pixelSize: Theme.fontSize
                        font.wordSpacing: -3
                    }
                }

                // ---- operated ----
                Row {
                    spacing: Theme.moduleSpacing

                    BarModule {
                        id: weatherModule

                        // The degree sign's side bearing.
                        opticalTrim: 2

                        popout: "weather"
                        activePopout: root.openPopout
                        onActivated: root.togglePopout("weather")

                        BarText {
                            text: Theme.glyph("weather") + " "
                                + (Weather.current ? Weather.currentOr.temp + "\u00b0" : "--")
                            color: Theme.barText
                            pixelSize: Theme.fontSize
                            font.wordSpacing: -3
                        }
                    }

                    TrayStrip {
                        id: trayStrip

                        onMenuRequested: (item, itemX) => {
                            trayMenu.trayItem = item;
                            root.openPopout = "traymenu";
                        }
                    }

                    // ---- keep awake ----
                    // Only while on. Click turns it off; the power popout turns it on.
                    BarModule {
                        visible: Idle.keepAwake
                        clickable: true
                        onActivated: Idle.keepAwake = false

                        BarText {
                            text: Theme.glyph("coffee")
                            color: Theme.mauve
                        }
                    }

                    // ---- recording ----
                    // Only while running. Click stops it.
                    BarModule {
                        visible: Recording.active

                        // No popout, so `clickable` must be set or the
                        // click never reaches activated().
                        clickable: true
                        onActivated: Recording.stop()

                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 9
                                height: 9
                                radius: width / 2
                                color: Theme.attention

                                SequentialAnimation on opacity {
                                    running: Recording.active
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 0.35; duration: 900 }
                                    NumberAnimation { to: 1.0;  duration: 900 }
                                }
                            }

                            BarText {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Recording.elapsedLabel
                                color: Theme.attention
                            }
                        }
                    }

                    // ---- pending updates ----
                    // Hidden at zero.
                    BarModule {
                        id: updatesModule

                        visible: Updates.total > 0
                        popout: "updates"
                        activePopout: root.openPopout

                        // Left click upgrades, right click shows the list.
                        onActivated: Updates.runUpgrade()
                        onSecondaryActivated: root.togglePopout("updates")

                        // Negative wordSpacing: the font has no thin space.
                        BarText {
                            text: Theme.glyph("updates") + " " + Updates.total
                            color: Theme.updatesColour(Updates.total)
                            font.wordSpacing: -3
                        }
                    }

                    // ---- notifications ----
                    // Always present, so the group does not shift as things arrive.
                    BarModule {
                        id: notifyModule

                        popout: "notifications"
                        activePopout: root.openPopout
                        onActivated: root.togglePopout("notifications")

                        // The count shows under DND too: DND means no
                        // interruptions, not no information.
                        BarText {
                            text: Theme.glyph(Notifications.doNotDisturb
                                    ? "bellOff" : "bell")
                                + (Notifications.count > 0
                                    ? " " + Notifications.count : "")

                            // Dim under DND; red means critical otherwise.
                            color: Notifications.doNotDisturb ? Theme.barDim
                                 : Notifications.hasCritical ? Theme.attention
                                 : Theme.barText

                            font.wordSpacing: -3
                        }
                    }

                    BarModule {
                        id: displayModule

                        popout: "display"
                        activePopout: root.openPopout
                        onActivated: root.togglePopout("display")

                        BarText {
                            text: Theme.glyph("display")
                            color: Theme.barText
                        }
                    }
                    BarModule {
                        id: volumeModule

                        popout: "volume"
                        activePopout: root.openPopout
                        onActivated: root.togglePopout("volume")

                        onWheeled: wheel => {
                            const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                            Audio.setVolume(Audio.volume + step);
                        }

                        BarText {
                            text: Theme.glyph(Audio.glyphName)
                            color: Audio.muted ? Theme.barDim : Theme.barText
                        }
                    }
                    BarModule {
                        id: networkModule

                        popout: "network"
                        activePopout: root.openPopout
                        onActivated: root.togglePopout("network")

                        BarText {
                            text: Theme.glyph(Network.glyphName)
                            color: Network.online
                                ? Theme.barText : Theme.barDim
                        }
                    }
                    // Hidden where there is no adapter.
                    BarModule {
                        id: bluetoothModule

                        visible: Bluetooth.present
                        popout: "bluetooth"
                        activePopout: root.openPopout
                        onActivated: root.togglePopout("bluetooth")

                        BarText {
                            text: Theme.glyph(Bluetooth.glyphName)
                            color: Bluetooth.powered ? Theme.barText : Theme.barDim
                        }
                    }
                    // Hidden with no battery (UPower reports no device).
                    BarModule {
                        id: batteryModule

                        visible: Battery.present
                        popout: "battery"
                        activePopout: root.openPopout
                        onActivated: root.togglePopout("battery")

                        // Negative wordSpacing: the font has no thin space,
                        // and a full space reads as a separate module.
                        BarText {
                            text: Battery.glyph + " " + Battery.percent + "%"
                            color: Battery.color
                            font.wordSpacing: -3
                        }
                    }
                }

                // ---- the clock, outermost ----
                BarModule {
                    id: clockModule

                    popout: "clock"
                    activePopout: root.openPopout
                    onActivated: root.togglePopout("clock")

                    BarText {
                        // HH, not hh: hh is 12-hour whenever AP is present.
                        text: Qt.formatDateTime(clock.date, "ddd, dd. MMM HH:mm")
                        color: Theme.barText
                        pixelSize: Theme.fontSize
                    }
                }
            }

            NetworkPopout {
                barWindow: bar
                anchorItem: networkModule
                shown: root.openPopout === "network"
                onDismissed: root.openPopout = ""
            }

            DisplayPopout {
                barWindow: bar
                anchorItem: displayModule
                shown: root.openPopout === "display"
                onDismissed: root.openPopout = ""
            }

            VolumePopout {
                barWindow: bar
                anchorItem: volumeModule
                shown: root.openPopout === "volume"
                onDismissed: root.openPopout = ""
            }
            ClockPopout {
                barWindow: bar
                anchorItem: clockModule
                shown: root.openPopout === "clock"
                onDismissed: root.openPopout = ""
            }
            WeatherPopout {
                barWindow: bar
                anchorItem: weatherModule
                shown: root.openPopout === "weather"
                onDismissed: root.openPopout = ""
            }

            MediaPopout {
                barWindow: bar
                anchorItem: mediaModule
                shown: root.openPopout === "media"
                onDismissed: root.openPopout = ""
            }

            UpdatesPopout {
                barWindow: bar
                anchorItem: updatesModule
                shown: root.openPopout === "updates"
                onDismissed: root.openPopout = ""
            }

            PowerPopout {
                barWindow: bar
                anchorItem: powerModule
                shown: root.openPopout === "power"
                onDismissed: root.openPopout = ""
            }

            MeetingPopout {
                barWindow: bar
                anchorItem: meetingModule
                shown: root.openPopout === "meeting"
                onDismissed: root.openPopout = ""
            }

            BatteryPopout {
                barWindow: bar
                anchorItem: batteryModule
                shown: root.openPopout === "battery"
                onDismissed: root.openPopout = ""
            }

            BluetoothPopout {
                barWindow: bar
                anchorItem: bluetoothModule
                shown: root.openPopout === "bluetooth"
                onDismissed: root.openPopout = ""
            }

            NotificationsPopout {
                barWindow: bar
                anchorItem: notifyModule
                shown: root.openPopout === "notifications"
                onDismissed: root.openPopout = ""
            }

            TrayMenuPopout {
                id: trayMenu

                barWindow: bar
                anchorItem: trayStrip
                shown: root.openPopout === "traymenu"
                onDismissed: root.openPopout = ""
            }
        }
    }

    // Shared text element: font plus a hover lift.
    component BarText: Text {
        property int pixelSize: Theme.fontSize

        font.family: Theme.fontFamily
        font.pixelSize: pixelSize
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        opacity: hover.hovered ? 1.0 : 0.85

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animDuration
                easing.type: Theme.animEasing
            }
        }

        HoverHandler { id: hover }
    }
}
