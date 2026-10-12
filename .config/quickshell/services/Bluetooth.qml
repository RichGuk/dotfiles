pragma Singleton

// Bluetooth, through BlueZ directly.
//   READ   busctl GetManagedObjects (ObjectManager is BlueZ's only listing API)
//   WATCH  `gdbus monitor` -- NOT dbus-monitor, which the system bus refuses
//          to an unprivileged user
//   ACT    bluetoothctl, which brings the agent pairing prompts need

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Set by the popout; speeds up the poll while it is open.
    property bool detailsVisible: false

    // ------------------------------------------------------------------
    // State
    // ------------------------------------------------------------------
    property bool present: false        // is there an adapter at all
    property bool powered: false
    property bool discovering: false
    property string adapterPath: ""
    property string adapterName: ""

    // { path, address, name, icon, paired, trusted, connected, blocked, rssi, battery }
    property var devices: []

    property string busy: ""            // address of a device mid-action
    property string lastError: ""

    readonly property var connectedDevices: {
        const out = [];
        for (const d of root.devices) if (d.connected) out.push(d);
        return out;
    }

    readonly property var pairedDevices: {
        const out = [];
        for (const d of root.devices) if (d.paired && !d.connected) out.push(d);
        return out;
    }

    readonly property var availableDevices: {
        const out = [];
        for (const d of root.devices) if (!d.paired && !d.connected) out.push(d);
        return out;
    }

    // ------------------------------------------------------------------
    // What the bar draws.
    // ------------------------------------------------------------------
    readonly property string glyphName:
        !present ? "bluetoothOff"
        : !powered ? "bluetoothOff"
        : connectedDevices.length > 0 ? "bluetoothOn"
        : "bluetooth"

    readonly property string label: {
        if (!present) return "No adapter";
        if (!powered) return "Off";
        const n = root.connectedDevices.length;
        if (n === 0) return "On";
        if (n === 1) return root.connectedDevices[0].name;
        return n + " connected";
    }

    function deviceGlyph(icon) {
        switch (icon) {
        case "audio-headset":
        case "audio-headphones":  return "headset";
        case "audio-card":        return "speaker";
        case "input-mouse":       return "mouse";
        case "input-keyboard":    return "keyboard";
        case "input-gaming":      return "gamepad";
        case "input-tablet":
        case "computer-tablet":   return "tablet";
        case "phone":             return "cellphone";
        case "computer":          return "laptop";
        case "printer":           return "printer";
        case "multimedia-player": return "music";
        default:                  return "bluetooth";
        }
    }

    // ------------------------------------------------------------------
    // Reading the object tree.
    // ------------------------------------------------------------------
    Process {
        id: readProc

        command: ["busctl", "--system", "--json=short", "call", "org.bluez", "/",
                  "org.freedesktop.DBus.ObjectManager", "GetManagedObjects"]

        stdout: StdioCollector {
            onStreamFinished: root.parseTree(this.text)
        }
    }

    // busctl wraps every value as { "type": ..., "data": ... }.
    function pv(iface, key, fallback) {
        if (!iface || !iface[key]) return fallback;
        const v = iface[key].data;
        return v === undefined ? fallback : v;
    }

    function parseTree(text) {
        if (!text) return;

        let objs;
        try {
            objs = JSON.parse(text).data[0];
        } catch (e) {
            // No org.bluez on the bus: busctl prints an error, not JSON.
            // That is the no-adapter case, not a fault.
            root.present = false;
            return;
        }

        let adapter = null;
        let adapterPath = "";
        const found = [];

        for (const path in objs) {
            const ifaces = objs[path];

            const a = ifaces["org.bluez.Adapter1"];
            if (a && !adapter) {
                adapter = a;
                adapterPath = path;
            }

            const d = ifaces["org.bluez.Device1"];
            if (!d) continue;

            // Battery is a separate interface on the same object, often absent.
            const bat = ifaces["org.bluez.Battery1"];

            const address = root.pv(d, "Address", "");
            if (!address) continue;

            found.push({
                path: path,
                address: address,
                // Alias is the user-renameable name other UIs show.
                name: root.pv(d, "Alias", "") || root.pv(d, "Name", "") || address,
                icon: root.pv(d, "Icon", ""),
                paired: !!root.pv(d, "Paired", false),
                trusted: !!root.pv(d, "Trusted", false),
                connected: !!root.pv(d, "Connected", false),
                blocked: !!root.pv(d, "Blocked", false),
                rssi: root.pv(d, "RSSI", 0),
                battery: bat ? root.pv(bat, "Percentage", -1) : -1
            });
        }

        // Within a group by name, not RSSI, so rows do not move under the pointer.
        found.sort((x, y) => {
            if (x.connected !== y.connected) return x.connected ? -1 : 1;
            if (x.paired !== y.paired) return x.paired ? -1 : 1;
            return x.name.localeCompare(y.name);
        });

        root.devices = found;
        root.present = !!adapter;
        root.adapterPath = adapterPath;
        root.powered = !!root.pv(adapter, "Powered", false);
        root.discovering = !!root.pv(adapter, "Discovering", false);
        root.adapterName = root.pv(adapter, "Alias", "")
                        || root.pv(adapter, "Name", "");
    }

    function refresh() {
        readProc.running = true;
    }

    // ------------------------------------------------------------------
    // Watching for changes.
    // ------------------------------------------------------------------
    Process {
        id: monitorProc

        command: ["gdbus", "monitor", "--system", "--dest", "org.bluez"]
        running: true

        stdout: SplitParser {
            splitMarker: "\n"
            // Debounced: one connect emits several PropertiesChanged.
            onRead: debounce.restart()
        }
    }

    Timer {
        id: debounce
        interval: 300
        onTriggered: root.refresh()
    }

    // ------------------------------------------------------------------
    // Actions, via bluetoothctl. Args are an array, so nothing reaches a shell.
    // ------------------------------------------------------------------
    Process { id: actionProc }

    function run(args) {
        actionProc.command = ["bluetoothctl"].concat(args);
        actionProc.running = true;
    }

    function setPowered(on) {
        root.lastError = "";
        root.run(["power", on ? "on" : "off"]);
    }

    function connect(address) {
        root.lastError = "";
        root.busy = address;
        root.run(["connect", address]);
    }

    function disconnect(address) {
        root.busy = address;
        root.run(["disconnect", address]);
    }

    function pair(address) {
        root.lastError = "";
        root.busy = address;
        root.run(["pair", address]);
    }

    function trust(address) {
        root.run(["trust", address]);
    }

    function forget(address) {
        root.busy = address;
        root.run(["remove", address]);
    }

    // Timed: BlueZ does not stop discovery on its own; --timeout ends it.
    function scan() {
        if (root.discovering) return;
        scanProc.running = true;
    }

    Process {
        id: scanProc
        command: ["bluetoothctl", "--timeout", "15", "scan", "on"]
        onExited: root.refresh()
    }

    Connections {
        target: actionProc
        function onExited(code, status) {
            root.busy = "";
            if (code !== 0) root.lastError = "That did not work";
            root.refresh();
        }
    }

    // ------------------------------------------------------------------
    // Polling: a backstop for the monitor, since RSSI drifts without a signal.
    // ------------------------------------------------------------------
    Timer {
        interval: root.detailsVisible ? 5000 : 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    onDetailsVisibleChanged: if (root.detailsVisible) root.lastError = "";
}
