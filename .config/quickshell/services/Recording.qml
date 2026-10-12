pragma Singleton

// Is a screen recording running, and where. hypr-screenrecord writes the state
// file and deletes it when the recorder exits for any reason. Stop goes back
// through the script, which knows SIGINT is needed to finalise the file.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string stateFile:
        (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state")
        + "/hyprland-shell/recording.json"

    readonly property string script:
        (Quickshell.env("HOME") || "") + "/.config/hypr/scripts/hypr-screenrecord"

    // A deleted file does NOT clear the adapter (it keeps the last values), so
    // presence is tracked separately, from load success.
    property bool present: false

    readonly property bool active: root.present && store.adapter.started > 0
    readonly property string mode: store.adapter.mode
    readonly property string what: store.adapter.what

    // Logical pixels; 0x0 for a whole-output recording.
    readonly property int x: store.adapter.x
    readonly property int y: store.adapter.y
    readonly property int width: store.adapter.w
    readonly property int height: store.adapter.h
    readonly property bool hasRegion: root.active && root.width > 0 && root.height > 0

    // Ticked by the timer: a binding on Date.now() never re-evaluates.
    property int elapsed: 0

    readonly property string elapsedLabel: {
        const m = Math.floor(root.elapsed / 60);
        const s = root.elapsed % 60;
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    function stop() {
        Quickshell.execDetached([root.script]);
    }

    Timer {
        running: root.active
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.elapsed =
            Math.max(0, Math.floor(Date.now() / 1000) - store.adapter.started)
    }

    FileView {
        id: store

        path: root.stateFile

        watchChanges: true
        printErrors: false      // absent whenever nothing is recording

        onFileChanged: reload()
        onLoaded: root.present = true
        onLoadFailed: root.present = false

        JsonAdapter {
            property string mode: ""
            property string what: ""
            property string file: ""
            property int x: 0
            property int y: 0
            property int w: 0
            property int h: 0
            property int started: 0
        }
    }
}
