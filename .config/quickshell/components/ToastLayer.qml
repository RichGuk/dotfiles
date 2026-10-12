// The window toasts live in: top-right, below the bar, above everything else.

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.theme
import qs.services

PanelWindow {
    id: root

    visible: Notifications.toasts.length > 0

    anchors {
        top: true
        right: true
    }

    margins {
        top: Theme.barHeight + Theme.toastGap
        right: Theme.edgeMargin
    }

    // The window is larger than the cards so the shadow has room.
    readonly property int shadowRoom: 24

    implicitWidth: Theme.toastWidth + shadowRoom * 2
    implicitHeight: Math.max(1, stack.implicitHeight + shadowRoom * 2)

    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-toasts"

    // Never take focus from what the user is typing into.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    exclusiveZone: 0

    // Without the mask the whole window swallows clicks, even where no toast is.
    mask: Region {
        item: stack
    }

    Column {
        id: stack

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: root.shadowRoom
        anchors.rightMargin: root.shadowRoom

        spacing: Theme.toastSpacing

        Repeater {
            model: Notifications.toasts

            Toast {
                required property var modelData
                notif: modelData
            }
        }
    }

    Rectangle {
        anchors.right: stack.right
        anchors.top: stack.bottom
        anchors.topMargin: Theme.toastSpacing
        visible: Notifications.hiddenToastCount > 0

        width: moreLabel.implicitWidth + 20
        height: 22
        radius: 11
        color: Theme.popoutBg
        border.width: Theme.popoutBorder
        border.color: Theme.popoutEdge

        Text {
            id: moreLabel

            anchors.centerIn: parent
            text: "+" + Notifications.hiddenToastCount + " more"
            color: Theme.overlay0
            font.family: Theme.fontFamily
            font.pixelSize: Theme.popoutBodySize - 2
        }
    }
}
