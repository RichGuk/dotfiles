pragma Singleton

// Keep-awake flag. The actual IdleInhibitor lives in shell.qml, since it must
// be attached to a window. Inhibits hypridle only; not persisted across restarts.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool keepAwake: false

    function toggle() {
        root.keepAwake = !root.keepAwake;
    }

    IpcHandler {
        target: "idle"

        function on(): void {
            root.keepAwake = true;
        }

        function off(): void {
            root.keepAwake = false;
        }

        function toggle(): void {
            root.toggle();
        }

        function status(): string {
            return root.keepAwake ? "inhibited" : "normal";
        }
    }
}
