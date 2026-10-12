pragma Singleton

// Pending package updates, split repo (checkupdates) vs AUR (yay/paru -Qua).
//
// checkupdates exits 2 when nothing is pending and 1 on a real error. It also
// locks a shared temp DB, so concurrent runs fail. With no AUR helper the AUR
// count is absent, not zero.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ------------------------------------------------------------------
    // Counts and package lists of {name, from, to}.
    // ------------------------------------------------------------------
    property var repoPackages: []
    property var aurPackages: []

    readonly property int repoCount: repoPackages.length
    readonly property int aurCount: aurPackages.length
    readonly property int total: repoCount + aurCount

    // Helper name, "" for none. Its -Syu also covers repo packages.
    property string aurHelper: ""
    readonly property bool aurAvailable: aurHelper !== ""

    // A check that errored, as distinct from one that found nothing.
    property bool repoFailed: false

    property bool busy: false
    property var lastChecked: null

    // ------------------------------------------------------------------
    // Each run is a real mirror sync, hence 15 minutes.
    // ------------------------------------------------------------------
    readonly property int refreshInterval: 15 * 60 * 1000

    function refresh() {
        if (root.busy) return;
        root.busy = true;
        root.repoFailed = false;
        repoProc.running = true;
        if (root.aurAvailable) aurProc.running = true;
    }

    function upgradeCommand() {
        return root.aurAvailable
            ? root.aurHelper + " -Syu"
            : "sudo pacman -Syu";
    }

    // Interactive on purpose: yay/pacman ask before applying.
    function runUpgrade() {
        const term = Quickshell.env("TERMINAL") || "foot";

        // Hold the terminal open after exit, or a failed upgrade's error vanishes.
        const inner = root.upgradeCommand()
            + '; printf "\n---- finished (exit %s), press enter to close ----\n" "$?"'
            + '; read _';

        // Single quotes: the inner double quotes and $? must reach the inner shell.
        Quickshell.execDetached(["sh", "-c", term + " sh -c '" + inner + "'"]);
    }

    // ------------------------------------------------------------------
    // Parsing. checkupdates and -Qua both print `name oldver -> newver`.
    // ------------------------------------------------------------------
    function parse(text) {
        const out = [];
        for (const raw of text.split("\n")) {
            const line = raw.trim();
            if (line === "") continue;
            // Whitespace split, so a line without an arrow still yields a name.
            const f = line.split(/\s+/);
            out.push({
                name: f[0],
                from: f[1] || "",
                to: f[3] || ""
            });
        }
        return out;
    }

    // ------------------------------------------------------------------
    // Find an AUR helper once, at startup. yay preferred over paru.
    // ------------------------------------------------------------------
    Process {
        id: helperProc

        running: true
        command: ["sh", "-c", "command -v yay || command -v paru || true"]

        stdout: StdioCollector {
            onStreamFinished: {
                const path = this.text.trim().split("\n")[0] || "";
                // Bare name, not path: it also goes into a terminal command line.
                root.aurHelper = path === ""
                    ? "" : path.split("/").pop();
                if (root.aurAvailable) aurProc.running = true;
            }
        }
    }

    Process {
        id: repoProc

        command: ["checkupdates"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.repoPackages = root.parse(this.text);
            }
        }

        onExited: (code, status) => {
            // 0 = updates listed, 2 = none pending, anything else = failure.
            if (code !== 0 && code !== 2) {
                root.repoFailed = true;
                root.repoPackages = [];
            }
            root.busy = false;
            root.lastChecked = new Date();
        }
    }

    Process {
        id: aurProc

        command: root.aurAvailable
            ? [root.aurHelper, "-Qua"]
            : ["true"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.aurPackages = root.parse(this.text);
            }
        }

        // A helper exits 1 when it finds nothing; that is not an error.
        onExited: (code, status) => {
            if (code !== 0 && code !== 1) root.aurPackages = [];
        }
    }

    Timer {
        interval: root.refreshInterval
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    // ------------------------------------------------------------------
    // Recount when pacman finishes. Pairs with system/pacman-hooks/50-shell-updates.hook,
    // which touches this stamp. /var/lib so it always exists: a watch on a
    // missing path may never fire.
    // ------------------------------------------------------------------
    FileView {
        path: "/var/lib/pacman-shell-stamp"

        watchChanges: true
        blockWrites: true
        printErrors: false   // absent until the hook is installed

        onFileChanged: {
            // reload() re-arms the watch.
            reload();
            settle.restart();
        }
    }

    // Debounced: an AUR helper runs several transactions, and each recount is a mirror sync.
    Timer {
        id: settle

        interval: 3000
        repeat: false
        onTriggered: root.refresh()
    }
}
