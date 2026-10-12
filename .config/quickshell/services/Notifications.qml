pragma Singleton

// Notifications. The shell IS the daemon: it owns org.freedesktop.Notifications,
// so no other notification daemon (mako, swaync) may run.
//
// trackedNotifications is the centre; `toasts` is the subset on screen. A toast
// timing out does NOT close the notification -- only an explicit dismiss does.

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.theme

Singleton {
    id: root

    // ------------------------------------------------------------------
    // Do not disturb. Suppresses toasts only; everything still reaches the centre.
    // ------------------------------------------------------------------
    property bool doNotDisturb: false

    // ------------------------------------------------------------------
    // The server. Capability flags change what senders do, so each one is a
    // claim about what this shell actually renders.
    // ------------------------------------------------------------------
    NotificationServer {
        id: server

        keepOnReload: true

        bodySupported: true

        bodyMarkupSupported: true

        // <a> would render but nothing opens links.
        bodyHyperlinksSupported: false
        bodyImagesSupported: false

        actionsSupported: true

        actionIconsSupported: false

        imageSupported: true

        inlineReplySupported: false

        persistenceSupported: true

        onNotification: n => root.onArrived(n)
    }

    // ------------------------------------------------------------------
    // The centre: everything still open, newest first.
    // ------------------------------------------------------------------
    readonly property var all: {
        if (!server.trackedNotifications) return [];
        const out = server.trackedNotifications.values.slice();
        out.reverse();
        return out;
    }

    readonly property int count: root.all.length

    readonly property bool hasCritical: {
        for (const n of root.all) {
            if (n && n.urgency === NotificationUrgency.Critical) return true;
        }
        return false;
    }

    // ------------------------------------------------------------------
    // Toasts. Held as IDs, not objects: a sender-closed notification is
    // destroyed, and a stale reference in a Repeater model crashes.
    // ------------------------------------------------------------------
    property var toastIds: []

    readonly property var toasts: {
        const out = [];
        if (!server.trackedNotifications) return out;

        for (const n of server.trackedNotifications.values) {
            if (n && root.toastIds.indexOf(n.id) !== -1) out.push(n);
        }
        out.reverse();                       // newest nearest the bar
        return out.slice(0, root.maxToasts);
    }

    readonly property int maxToasts: 4

    readonly property int hiddenToastCount:
        Math.max(0, root.toastIds.length - root.maxToasts)

    function onArrived(n) {
        if (!n) return;

        // Without this the notification is destroyed when the handler returns,
        // silently, while the daemon still looks healthy.
        n.tracked = true;

        // Survived a config reload: not new, do not re-toast.
        if (n.lastGeneration) return;

        if (root.doNotDisturb) {
            // A transient under DND is never toasted, so nothing would retire it.
            if (n.transient) n.dismiss();
            return;
        }

        root.toastIds = root.toastIds.concat([n.id]);
    }

    // Called when a toast's countdown ends; the notification stays in the centre.
    function untoast(n) {
        if (!n) return;
        root.toastIds = root.toastIds.filter(x => x !== n.id);

        if (n.transient) n.dismiss();
    }

    // Really closes it.
    function dismiss(n) {
        if (!n) return;
        root.toastIds = root.toastIds.filter(x => x !== n.id);
        n.dismiss();
    }

    function dismissAll() {
        // Copied first: dismissing mutates the tracked list.
        for (const n of root.all.slice()) {
            if (n) n.dismiss();
        }
        root.toastIds = [];
    }

    // ------------------------------------------------------------------
    // Toast lifetime. The sender's expireTimeout wins; critical never expires.
    // ------------------------------------------------------------------
    function timeoutFor(n) {
        if (!n) return 0;
        if (n.urgency === NotificationUrgency.Critical) return 0;

        // Milliseconds; -1 means "server decides".
        if (n.expireTimeout > 0) return n.expireTimeout;

        return n.urgency === NotificationUrgency.Low ? 4000 : 6000;
    }

    // ------------------------------------------------------------------
    // Display helpers.
    // ------------------------------------------------------------------
    function urgencyColour(n) {
        if (!n) return Theme.popoutEdge;
        switch (n.urgency) {
        case NotificationUrgency.Critical: return Theme.attention;
        case NotificationUrgency.Low:      return Theme.overlay0;
        default:                           return Theme.mauve;
        }
    }

    function urgencyGlyph(n) {
        if (!n) return "bell";
        return n.urgency === NotificationUrgency.Critical
            ? "alertCircle" : "bell";
    }

    function appLabel(n) {
        if (!n) return "";
        return n.appName || n.desktopEntry || "Notification";
    }

    function ago(ms) {
        const mins = Math.floor((Date.now() - ms) / 60000);
        if (mins < 1) return "now";
        if (mins < 60) return mins + "m";
        const h = Math.floor(mins / 60);
        if (h < 24) return h + "h";
        return Math.floor(h / 24) + "d";
    }

    // The protocol carries no arrival time, so it is recorded here.
    property var arrivedAt: ({})

    Connections {
        target: server
        function onNotification(n) {
            if (!n) return;
            const next = {};
            for (const k in root.arrivedAt) next[k] = root.arrivedAt[k];
            next[n.id] = Date.now();
            root.arrivedAt = next;
        }
    }

    function arrivalOf(n) {
        if (!n) return Date.now();
        const t = root.arrivedAt[n.id];
        return t === undefined ? Date.now() : t;
    }
}
