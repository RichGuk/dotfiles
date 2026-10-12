pragma Singleton

// Meetings, via `~/Scripts/next-meeting` (outside this repo; shared with the
// Mac's sketchybar) which calls gogcli. Shows nothing if the script is missing.
// `--json` applies the bar's lookahead horizon; `--list` gives the whole day.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // $HOME is expanded by the `sh -c` below.
    readonly property string script: "$HOME/Scripts/next-meeting"

    // Inside the horizon, or null. The script returns {} once a meeting ends.
    property var current: null

    property var all: []

    // Distinguishes "no meetings" from "have not looked yet".
    property bool loaded: false

    // The script could not be run at all -- distinct from an empty diary.
    property bool failed: false

    readonly property bool hasMeeting: !!root.current
    readonly property string label: root.current ? root.current.text : ""
    readonly property string url: root.current ? (root.current.url || "") : ""

    readonly property var upcoming: {
        const out = [];
        for (const m of root.all) {
            if (m.state === "upcoming") out.push(m);
        }
        return out;
    }

    readonly property var running: {
        const out = [];
        for (const m of root.all) {
            if (m.state === "now") out.push(m);
        }
        return out;
    }

    function refresh() {
        currentProc.running = true;
        listProc.running = true;
    }

    function openUrl(link) {
        if (!link) return;
        Quickshell.execDetached(["xdg-open", link]);
    }

    function openCurrent() {
        root.openUrl(root.url);
    }

    Process {
        id: currentProc

        command: ["sh", "-c", "exec " + root.script + " --json"]

        stdout: StdioCollector {
            onStreamFinished: {
                const text = this.text.trim();
                if (text === "") {
                    root.current = null;
                    return;
                }
                try {
                    const obj = JSON.parse(text);
                    // {} means nothing to show; normalise it to null.
                    root.current = obj && obj.title ? obj : null;
                } catch (e) {
                    root.current = null;
                }
            }
        }

        onExited: (code, status) => {
            root.failed = code !== 0;
            root.loaded = true;
        }
    }

    Process {
        id: listProc

        command: ["sh", "-c", "exec " + root.script + " --list"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const arr = JSON.parse(this.text.trim() || "[]");
                    root.all = Array.isArray(arr) ? arr : [];
                } catch (e) {
                    root.all = [];
                }
            }
        }
    }

    // The script caches for five minutes, so most polls never reach Google.
    Timer {
        interval: 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
