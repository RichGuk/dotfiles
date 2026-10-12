pragma Singleton

// Session and machine power actions, via systemctl/logind (so polkit and
// inhibitors apply). Hibernate is offered only if swap >= RAM; the kernel
// listing `disk` in /sys/power/state is not enough.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool canHibernate: false
    property bool checked: false

    function suspend() {
        run(["systemctl", "suspend"]);
    }

    function hibernate() {
        if (!root.canHibernate) return;
        run(["systemctl", "hibernate"]);
    }

    function reboot() {
        run(["systemctl", "reboot"]);
    }

    function shutdown() {
        run(["systemctl", "poweroff"]);
    }

    // Lua-config form: `dispatch exit` parses its argument as Lua.
    function logout() {
        run(["hyprctl", "dispatch", "hl.dsp.exit()"]);
    }

    function run(argv) {
        Quickshell.execDetached(argv);
    }

    // Swap total against MemTotal, checked once at startup.
    Process {
        running: true

        command: ["sh", "-c",
            "grep -q disk /sys/power/state 2>/dev/null || { echo no; exit 0; }; "
            + "mem=$(awk '/^MemTotal:/{print $2}' /proc/meminfo); "
            + "swap=$(awk 'NR>1{s+=$3} END{print s+0}' /proc/swaps); "
            + "[ \"${swap:-0}\" -ge \"$mem\" ] && echo yes || echo no"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.canHibernate = this.text.trim() === "yes";
                root.checked = true;
            }
        }
    }
}
