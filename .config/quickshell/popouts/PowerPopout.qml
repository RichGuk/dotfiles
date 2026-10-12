// ---------------- power menu ----------------
// Log out, restart and shut down need a second click; the rest fire at once.

import QtQuick
import Quickshell
import qs.theme
import qs.components
import qs.services

Popout {
    id: root

    // Wide enough for "Click again to confirm" not to elide.
    contentWidth: 280

    contentHeight: Theme.popoutPadding * 2 + menu.implicitHeight

    // Which entry is waiting for its second click, "" for none.
    property string armed: ""

    Connections {
        target: root
        function onShownChanged() {
            if (!root.shown) root.armed = "";
        }
    }

    Column {
        id: menu

        anchors.fill: parent
        anchors.margins: Theme.popoutPadding
        spacing: 2

        PowerItem {
            glyph: "coffee"
            label: Idle.keepAwake ? "Keep awake — on" : "Keep awake"
            onTriggered: {
                Idle.toggle();
                root.dismiss();
            }
        }

        PowerItem {
            glyph: "lock"
            label: "Lock"
            onTriggered: {
                Lock.lock();
                root.dismiss();
            }
        }

        PowerItem {
            glyph: "sleep"
            label: "Sleep"
            onTriggered: {
                Power.suspend();
                root.dismiss();
            }
        }

        PowerItem {
            glyph: "hibernate"
            label: "Hibernate"
            visible: Power.canHibernate
            onTriggered: {
                Power.hibernate();
                root.dismiss();
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Theme.popoutEdge
            opacity: 0.6
        }

        PowerItem {
            id: logoutItem

            glyph: "logout"
            label: "Log out"
            confirms: true
            armed: root.armed === "logout"
            onTriggered: root.arm("logout", Power.logout)
        }

        PowerItem {
            glyph: "restart"
            label: "Restart"
            confirms: true
            armed: root.armed === "restart"
            danger: true
            onTriggered: root.arm("restart", Power.reboot)
        }

        PowerItem {
            glyph: "power"
            label: "Shut down"
            confirms: true
            armed: root.armed === "shutdown"
            danger: true
            onTriggered: root.arm("shutdown", Power.shutdown)
        }
    }

    // First click arms, second fires. Arming one disarms any other.
    function arm(name, action) {
        if (root.armed === name) {
            root.armed = "";
            root.dismiss();
            action();
            return;
        }
        root.armed = name;
    }

    component PowerItem: Rectangle {
        id: item

        property string glyph: ""
        property string label: ""
        property bool confirms: false
        property bool armed: false
        property bool danger: false

        signal triggered()

        width: parent ? parent.width : 0
        height: 38
        radius: Theme.popoutCardRadius

        color: item.armed
            ? (item.danger ? "#33f38ba8" : Theme.surface1)
            : (hover.hovered ? Theme.surface0 : "transparent")

        Behavior on color {
            ColorAnimation { duration: Theme.animDuration }
        }

        readonly property color tint: item.armed && item.danger
            ? Theme.attention
            : (item.danger && hover.hovered ? Theme.attention : Theme.text)

        Text {
            id: icon

            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: Theme.glyph(item.glyph)
            color: item.tint
            font.family: Theme.fontFamily
            font.pixelSize: Theme.popoutBodySize + 2

            Behavior on color {
                ColorAnimation { duration: Theme.animDuration }
            }
        }

        Text {
            anchors.left: icon.right
            anchors.leftMargin: 12
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: item.armed ? "Click again to confirm" : item.label
            color: item.armed ? item.tint : Theme.text
            elide: Text.ElideRight
            font.family: Theme.fontFamily
            font.pixelSize: Theme.popoutBodySize
        }

        HoverHandler { id: hover }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: item.triggered()
        }
    }
}
