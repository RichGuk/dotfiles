pragma Singleton

// The system tray, via StatusNotifierItem.
// Quickshell claims org.kde.StatusNotifierWatcher only once this module is
// used; applets started before that have nowhere to register.

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray

Singleton {
    id: root

    // ------------------------------------------------------------------
    // Filtering, from the hand-edited tray.json.
    // ------------------------------------------------------------------
    FileView {
        id: rules

        path: Quickshell.env("HOME") + "/.config/quickshell/tray.json"

        watchChanges: true
        onFileChanged: reload()

        // Never write: it would reformat the user's file.
        blockWrites: true
        printErrors: false

        JsonAdapter {
            id: cfg

            property list<string> hidden: []
            property list<string> pinned: []
            property list<string> only: []
            property var icons: ({})
        }
    }

    // Substring match: some SNI ids carry a pid or instance number.
    function matches(id, list) {
        if (!id || !list) return false;
        const needle = id.toLowerCase();
        for (const entry of list) {
            if (entry && needle.includes(String(entry).toLowerCase())) return true;
        }
        return false;
    }

    // ------------------------------------------------------------------
    // The items: all, pinned into the bar, and behind the drawer.
    // ------------------------------------------------------------------
    readonly property var allItems: SystemTray.items ? SystemTray.items.values : []

    function visible(item) {
        if (!item) return false;
        if (root.matches(item.id, cfg.hidden)) return false;
        // A non-empty `only` turns the whole thing into a whitelist.
        if (cfg.only && cfg.only.length > 0) {
            return root.matches(item.id, cfg.only);
        }
        return true;
    }

    readonly property var pinnedItems: {
        const out = [];
        for (const i of root.allItems) {
            if (root.visible(i) && root.matches(i.id, cfg.pinned)) out.push(i);
        }
        return out;
    }

    readonly property var drawerItems: {
        const out = [];
        for (const i of root.allItems) {
            if (root.visible(i) && !root.matches(i.id, cfg.pinned)) out.push(i);
        }
        return out;
    }

    readonly property int count: pinnedItems.length + drawerItems.length

    // ------------------------------------------------------------------
    // Icons. `icons` in tray.json overrides an item's own.
    // ------------------------------------------------------------------
    function iconFor(item) {
        if (!item) return "";

        for (const key in cfg.icons) {
            if (item.id && item.id.toLowerCase().includes(key.toLowerCase())) {
                const sub = cfg.icons[key];
                // A path if it looks like one, otherwise a theme icon name.
                return sub.includes("/")
                    ? Qt.resolvedUrl(sub) : Quickshell.iconPath(sub);
            }
        }

        let icon = item.icon;
        if (!icon) return "";

        // "name?path=/dir": an icon name plus a private search path, which does
        // not resolve as-is. Prefer a themed match, else the app's file.
        if (icon.includes("?path=")) {
            const [name, path] = icon.split("?path=");
            const file = name.slice(name.lastIndexOf("/") + 1);
            const themed = Quickshell.iconPath(file, true);
            icon = themed ? themed : Qt.resolvedUrl(path + "/" + file);
        }
        return icon;
    }

    // ------------------------------------------------------------------
    // Logs each new id once: those ids are what tray.json rules match.
    // ------------------------------------------------------------------
    property var seen: ({})

    onAllItemsChanged: {
        for (const i of root.allItems) {
            if (!i || !i.id || root.seen[i.id]) continue;
            root.seen[i.id] = true;
            console.log("Tray: item id=\"" + i.id + "\" title=\""
                        + (i.title || "") + "\" status=" + i.status
                        + " hasMenu=" + i.hasMenu);
        }
    }

    function label(item) {
        if (!item) return "";
        return item.tooltipTitle || item.title || item.id;
    }

    function needsAttention(item) {
        return !!item && item.status === Status.NeedsAttention;
    }

    function isPassive(item) {
        return !!item && item.status === Status.Passive;
    }
}
