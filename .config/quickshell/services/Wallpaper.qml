pragma Singleton

// The desktop background: no daemon. The choice lives in wallpaper.json, which
// config/hypr/scripts/hypr-wallpaper also writes; WallpaperLayer watches it.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string stateFile:
        (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state")
        + "/hyprland-shell/wallpaper.json"

    // Hyprland's bundled images, used when nothing has been chosen.
    readonly property var fallbacks: [
        "/usr/share/hypr/wall0.png",
        "/usr/share/hypr/wall1.png",
        "/usr/share/hypr/wall2.png"
    ]

    readonly property string path: store.adapter.path || root.fallbacks[0]

    // fill = crop to cover, fit = letterbox, stretch = ignore aspect.
    readonly property string mode: store.adapter.mode || "fill"

    readonly property int fillMode: {
        switch (root.mode) {
        case "fit":     return Image.PreserveAspectFit;
        case "stretch": return Image.Stretch;
        default:        return Image.PreserveAspectCrop;
        }
    }

    // ------------------------------------------------------------------
    // The picker. The list comes from `hypr-wallpaper list` so the shell and
    // the CLI agree on what counts as an image.
    // ------------------------------------------------------------------
    property var available: []
    property bool pickerOpen: false
    property bool scanning: false

    function openPicker() {
        root.refreshAvailable();
        root.pickerOpen = true;
    }

    function closePicker() {
        root.pickerOpen = false;
    }

    function refreshAvailable() {
        if (root.scanning) return;
        root.scanning = true;
        listProc.running = true;
    }

    Process {
        id: listProc

        command: ["sh", "-c",
            "exec $HOME/.config/hypr/scripts/hypr-wallpaper list"]

        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of this.text.split("\n")) {
                    const p = line.trim();
                    if (p !== "") out.push(p);
                }
                root.available = out;
            }
        }

        onExited: root.scanning = false
    }

    function setWallpaper(file) {
        if (!file) return;
        store.adapter.path = file;
        store.writeAdapter();
    }

    function setMode(m) {
        store.adapter.mode = m;
        store.writeAdapter();
    }

    // Cycles the bundled images only.
    function cycle() {
        const i = root.fallbacks.indexOf(root.path);
        root.setWallpaper(root.fallbacks[(i + 1) % root.fallbacks.length]);
    }

    IpcHandler {
        target: "wallpaper"

        function open(): void {
            root.openPicker();
        }

        function close(): void {
            root.closePicker();
        }

        function toggle(): void {
            if (root.pickerOpen) root.closePicker();
            else root.openPicker();
        }

        function next(): void {
            root.cycle();
        }

        function current(): string {
            return root.path;
        }
    }

    FileView {
        id: store

        path: root.stateFile

        watchChanges: true
        atomicWrites: true
        printErrors: false     // absent on first run, which is normal

        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        JsonAdapter {
            property string path: ""
            property string mode: "fill"
        }
    }
}
