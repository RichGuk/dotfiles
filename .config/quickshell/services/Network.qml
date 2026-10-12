pragma Singleton

// Networking: NetworkManager via nmcli when present, addresses via `ip -j addr`.
// NM is optional (this machine runs systemd-networkd); every nmcli call is
// gated on hasNetworkManager, and `ip` keeps the bar correct without it.

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ------------------------------------------------------------------
    // Set by the popout. Expensive polling (ping, rescan) runs only while open.
    // ------------------------------------------------------------------
    property bool detailsVisible: false

    // ------------------------------------------------------------------
    // Is NetworkManager here at all? Probed once; without the gate every nmcli
    // Process fails to start and logs on each tick.
    // ------------------------------------------------------------------
    property bool hasNetworkManager: false

    Process {
        id: nmProbe

        command: ["sh", "-c", "command -v nmcli >/dev/null 2>&1"]
        running: true

        onExited: code => {
            root.hasNetworkManager = (code === 0);
            if (root.hasNetworkManager) {
                root.refresh();
                // Deferred: NM may still be enumerating devices this early.
                startupScan.start();
            }
        }
    }

    // ------------------------------------------------------------------
    // State
    // ------------------------------------------------------------------
    // One entry per device: { iface, type, state, connection }
    property var devices: []

    // One entry per visible network: { ssid, signal, security, active, known }
    property var wifiNetworks: []

    // One entry per saved NM connection: { name, type, active, device }
    property var connections: []

    property bool wifiEnabled: true
    property bool wifiPresent: false

    // Keyed by interface name: { iface: [ "10.0.2.15/24", ... ] }
    property var addresses: ({})

    property string publicIp: ""
    property real latencyMs: -1
    property real packetLoss: -1

    // Set while a join is in flight.
    property string connecting: ""
    property string lastError: ""

    // ------------------------------------------------------------------
    // What the bar draws.
    // ------------------------------------------------------------------
    readonly property var primary: {
        for (const d of root.devices) {
            if (d.state === "connected" && d.type === "wifi") return d;
        }
        for (const d of root.devices) {
            if (d.state === "connected" && d.type === "ethernet") return d;
        }
        return null;
    }

    readonly property bool online: !!root.primary || root.wiredUp

    // From `ip`, so it is right for devices NM does not manage (or without NM).
    readonly property bool wiredUp: {
        for (const iface in root.addresses) {
            if (iface === "lo" || iface.startsWith("wlan")) continue;
            for (const a of root.addresses[iface]) {
                if (a.indexOf(":") === -1) return true;
            }
        }
        return false;
    }

    readonly property var activeWifi: {
        for (const n of root.wifiNetworks) {
            if (n.active) return n;
        }
        return null;
    }

    function signalGlyph(strength) {
        if (strength >= 76) return "wifi4";
        if (strength >= 51) return "wifi3";
        if (strength >= 26) return "wifi2";
        return "wifi1";
    }

    readonly property string glyphName: {
        if (root.activeWifi) return root.signalGlyph(root.activeWifi.signal);
        if (root.wiredUp) return "lan";
        if (!root.wifiEnabled) return "wifiOff";
        return "networkDown";
    }

    readonly property string label: {
        if (root.activeWifi) return root.activeWifi.ssid;
        if (root.wiredUp) return "Wired";
        return "Offline";
    }

    // One row per address: wired, then wireless, then tunnels; v4 before v6.
    // Loopback dropped.
    readonly property var addressRows: {
        const rows = [];
        const names = Object.keys(root.addresses).sort();

        function push(pred) {
            for (const iface of names) {
                if (iface === "lo") continue;
                if (!pred(iface)) continue;
                const wireless = iface.startsWith("wlan")
                              || iface.startsWith("wlp");
                const tunnel = iface.startsWith("wg");
                const v4 = root.addresses[iface].filter(a => a.indexOf(":") === -1);
                const v6 = root.addresses[iface].filter(a => a.indexOf(":") !== -1);
                for (const a of v4.concat(v6)) {
                    rows.push({
                        iface: iface, address: a,
                        wireless: wireless, tunnel: tunnel
                    });
                }
            }
        }

        push(i => !i.startsWith("wlan") && !i.startsWith("wlp")
                && !i.startsWith("wg"));
        push(i => i.startsWith("wlan") || i.startsWith("wlp"));
        push(i => i.startsWith("wg"));
        return rows;
    }

    // WireGuard tunnels are NM connections of type `wireguard`.
    readonly property var tunnels: {
        const out = [];
        for (const c of root.connections) {
            if (c.type === "wireguard") out.push(c);
        }
        return out;
    }

    readonly property bool anyTunnelUp: {
        for (const t of root.tunnels) {
            if (t.active) return true;
        }
        return false;
    }

    // ------------------------------------------------------------------
    // Parsing `nmcli -t`: colon-separated, literal colons backslash-escaped
    // (BSSIDs, IPv6), so a plain split() is wrong.
    // ------------------------------------------------------------------
    function splitTerse(line) {
        const out = [];
        let cur = "";
        for (let i = 0; i < line.length; i++) {
            const c = line[i];
            if (c === "\\" && i + 1 < line.length) {
                cur += line[++i];
            } else if (c === ":") {
                out.push(cur);
                cur = "";
            } else {
                cur += c;
            }
        }
        out.push(cur);
        return out;
    }

    function lines(text) {
        return text.split("\n").filter(l => l.length > 0);
    }

    // ------------------------------------------------------------------
    // Devices, and the radio state.
    // ------------------------------------------------------------------
    Process {
        id: deviceProc

        command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "device"]

        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                let sawWifi = false;
                for (const l of root.lines(this.text)) {
                    const f = root.splitTerse(l);
                    if (f.length < 4) continue;
                    // p2p-dev-* are wifi-direct shadows, never user-pickable.
                    if (f[0].startsWith("p2p-dev-")) continue;
                    if (f[1] === "wifi") sawWifi = true;
                    out.push({
                        iface: f[0], type: f[1], state: f[2], connection: f[3]
                    });
                }
                root.devices = out;
                root.wifiPresent = sawWifi;
            }
        }
    }

    Process {
        id: radioProc

        command: ["nmcli", "-t", "-f", "WIFI", "radio"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiEnabled = this.text.trim() === "enabled";
            }
        }
    }

    // ------------------------------------------------------------------
    // Addresses, from iproute2 rather than NM.
    // ------------------------------------------------------------------
    Process {
        id: addrProc

        command: ["ip", "-j", "addr"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const map = {};
                    for (const link of JSON.parse(this.text)) {
                        const addrs = [];
                        for (const a of (link.addr_info || [])) {
                            // Link-local is on every interface; not worth a row.
                            if (a.scope === "link") continue;
                            addrs.push(a.local + "/" + a.prefixlen);
                        }
                        if (addrs.length) map[link.ifname] = addrs;
                    }
                    root.addresses = map;
                } catch (e) {
                    console.warn("Network: could not parse ip -j addr:", e);
                }
            }
        }
    }

    // ------------------------------------------------------------------
    // Saved connections: the WireGuard list and the "known" flag for wifi rows.
    // ------------------------------------------------------------------
    Process {
        id: connProc

        command: ["nmcli", "-t", "-f", "NAME,TYPE,ACTIVE,DEVICE",
                  "connection", "show"]

        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const l of root.lines(this.text)) {
                    const f = root.splitTerse(l);
                    if (f.length < 3) continue;
                    out.push({
                        name: f[0],
                        type: f[1] === "802-11-wireless" ? "wifi" : f[1],
                        active: f[2] === "yes",
                        device: f[3] || ""
                    });
                }
                root.connections = out;
            }
        }
    }

    function isKnown(ssid) {
        for (const c of root.connections) {
            if (c.type === "wifi" && c.name === ssid) return true;
        }
        return false;
    }

    // ------------------------------------------------------------------
    // Wifi list, from NM's cache. Rescanning is separate and slow.
    // ------------------------------------------------------------------
    Process {
        id: wifiProc

        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY",
                  "device", "wifi", "list"]

        stdout: StdioCollector {
            onStreamFinished: {
                const seen = {};
                const out = [];
                for (const l of root.lines(this.text)) {
                    const f = root.splitTerse(l);
                    if (f.length < 4) continue;

                    const ssid = f[1];
                    // Hidden networks have an empty SSID and cannot be clicked to join.
                    if (!ssid) continue;

                    const signal = parseInt(f[2], 10) || 0;

                    // One row per SSID (a mesh shows one per BSSID); strongest wins.
                    if (ssid in seen) {
                        const prev = out[seen[ssid]];
                        if (signal > prev.signal) prev.signal = signal;
                        if (f[0] === "*") prev.active = true;
                        continue;
                    }

                    seen[ssid] = out.length;
                    out.push({
                        ssid: ssid,
                        signal: signal,
                        security: f[3],
                        // "--" is nmcli for open.
                        open: !f[3] || f[3] === "--",
                        active: f[0] === "*",
                        known: root.isKnown(ssid)
                    });
                }
                out.sort((a, b) => {
                    // Connected first, then by strength.
                    if (a.active !== b.active) return a.active ? -1 : 1;
                    return b.signal - a.signal;
                });
                root.wifiNetworks = out;
            }
        }
    }

    Process {
        id: rescanProc
        command: ["nmcli", "device", "wifi", "rescan"]
        // Exits non-zero if a rescan is already running; harmless.
        onExited: wifiProc.running = true
    }

    function rescan() {
        if (!root.wifiEnabled || rescanProc.running) return;
        rescanProc.running = true;
    }

    // ------------------------------------------------------------------
    // Reachability. Only while the popout is open.
    // ------------------------------------------------------------------
    Process {
        id: pingProc

        // By address, so a DNS failure is not mistaken for a dead link.
        command: ["ping", "-c", "3", "-W", "2", "-q", "1.1.1.1"]

        stdout: StdioCollector {
            onStreamFinished: {
                const loss = this.text.match(/([\d.]+)% packet loss/);
                root.packetLoss = loss ? parseFloat(loss[1]) : -1;

        // -q prints one summary line: min/avg/max/mdev.
                const rtt = this.text.match(
                    /=\s*[\d.]+\/([\d.]+)\/[\d.]+\/[\d.]+\s*ms/);
                root.latencyMs = rtt ? parseFloat(rtt[1]) : -1;
            }
        }
    }

    // ------------------------------------------------------------------
    // Public IP, from ip-api's `query` field (free tier is HTTP-only).
    // ------------------------------------------------------------------
    function fetchPublicIp() {
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            if (xhr.status !== 200) {
                root.publicIp = "";
                return;
            }
            try {
                const d = JSON.parse(xhr.responseText);
                root.publicIp = d.query || "";
            } catch (e) {
                root.publicIp = "";
            }
        };
        xhr.open("GET", "http://ip-api.com/json/?fields=query");
        xhr.send();
    }

    // ------------------------------------------------------------------
    // Actions
    // ------------------------------------------------------------------
    Process { id: actionProc }

    // Args are an array, so SSIDs never reach a shell.
    function connectWifi(ssid, password) {
        root.lastError = "";
        root.connecting = ssid;

        // `device wifi connect` activates a saved profile or creates one.
        const cmd = ["nmcli", "device", "wifi", "connect", ssid];
        if (password) cmd.push("password", password);

        actionProc.command = cmd;
        actionProc.running = true;
    }

    function disconnectWifi() {
        for (const d of root.devices) {
            if (d.type === "wifi" && d.state === "connected") {
                actionProc.command = ["nmcli", "device", "disconnect", d.iface];
                actionProc.running = true;
                return;
            }
        }
    }

    function forget(ssid) {
        actionProc.command = ["nmcli", "connection", "delete", ssid];
        actionProc.running = true;
    }

    // ------------------------------------------------------------------
    // Copying an address. Own Process: wl-copy stays resident to serve the
    // selection, so sharing actionProc would leave it stuck running.
    // ------------------------------------------------------------------
    Process { id: copyProc }

    // The value most recently copied, briefly, so the clicked row can say so.
    property string copied: ""

    Timer {
        id: copiedReset
        interval: 1400
        onTriggered: root.copied = ""
    }

    function copy(text) {
        if (!text) return;
        copyProc.command = ["wl-copy", "--", text];
        copyProc.running = true;
        root.copied = text;
        copiedReset.restart();
    }

    function setWifiEnabled(on) {
        actionProc.command = ["nmcli", "radio", "wifi", on ? "on" : "off"];
        actionProc.running = true;
    }

    function setTunnel(name, up) {
        actionProc.command = ["nmcli", "connection", up ? "up" : "down", name];
        actionProc.running = true;
    }

    // Whatever an action did, the state it changed is now stale.
    Connections {
        target: actionProc
        function onExited(code, status) {
            root.connecting = "";
            if (code !== 0) {
                root.lastError = "Could not connect";
            }
            root.refresh();
        }
    }

    // ------------------------------------------------------------------
    // Refresh, and what drives it.
    // ------------------------------------------------------------------
    function refresh() {
        // `ip` needs nothing installed, so it runs with or without NM.
        addrProc.running = true;

        if (!root.hasNetworkManager) return;

        deviceProc.running = true;
        radioProc.running = true;
        connProc.running = true;

        // Unconditional: gating on wifiPresent skips the first pass after a
        // reload, because wifiPresent is only known once deviceProc has parsed.
        wifiProc.running = true;
    }

    // `nmcli monitor` prints a line on every change: event-driven, not polled.
    Process {
        id: monitorProc

        command: ["nmcli", "monitor"]
        running: root.hasNetworkManager

        stdout: SplitParser {
            splitMarker: "\n"
            // Debounced: one change emits several lines.
            onRead: debounce.restart()
        }
    }

    Timer {
        id: debounce
        interval: 400
        onTriggered: root.refresh()
    }

    // Slow tick: signal strength drifts without an NM event.
    Timer {
        interval: 30000
        running: root.hasNetworkManager
        repeat: true
        onTriggered: {
            deviceProc.running = true;
            if (root.wifiPresent && root.wifiEnabled) wifiProc.running = true;
        }
    }

    // Fast tick, only while the popout is open.
    Timer {
        interval: 10000
        running: root.detailsVisible
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            addrProc.running = true;
            pingProc.running = true;
            if (root.wifiPresent && root.wifiEnabled) root.rescan();
        }
    }

    onDetailsVisibleChanged: {
        if (root.detailsVisible) {
            root.lastError = "";
            // Fetched on open; cached because `nmcli monitor` reports network changes.
            if (!root.publicIp) root.fetchPublicIp();
        }
    }

    // Only the `ip` half here; nmProbe starts the NM half once nmcli is found.
    Component.onCompleted: root.refresh()

    Timer {
        id: startupScan
        interval: 2000
        onTriggered: root.refresh()
    }
}
