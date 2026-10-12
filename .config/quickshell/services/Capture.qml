pragma Singleton

// Capture chooser state. Recording itself is config/hypr/scripts/hypr-screenrecord,
// which the SUPER+SHIFT+5 bind also runs.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool pickerOpen: false

    readonly property string script:
        (Quickshell.env("HOME") || "") + "/.config/hypr/scripts/hypr-screenrecord"

    readonly property var modes: [
        { mode: "output", label: "Screen", glyph: "display", detail: "focused monitor" },
        { mode: "region", label: "Area",   glyph: "crop",    detail: "drag a box" },
        { mode: "window", label: "Window", glyph: "window",  detail: "focused window" }
    ]

    function open()  { root.pickerOpen = true;  }
    function close() { root.pickerOpen = false; }

    // Close BEFORE starting: `region` runs slurp, and this overlay would
    // swallow the drag. The delay is for the surface to actually go away.
    function record(mode) {
        root.pickerOpen = false;
        startTimer.mode = mode;
        startTimer.restart();
    }

    Timer {
        id: startTimer

        property string mode: "output"

        interval: 200
        onTriggered: Quickshell.execDetached([root.script, startTimer.mode])
    }

    IpcHandler {
        target: "capture"

        function open(): void {
            root.open();
        }

        function close(): void {
            root.close();
        }

        function toggle(): void {
            if (root.pickerOpen) root.close();
            else root.open();
        }
    }
}
