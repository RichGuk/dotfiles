// One tray item: the app's own icon, via Tray.iconFor.

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import qs.theme
import qs.services

Item {
    id: root

    required property var item

    signal menuRequested(real x)

    width: Theme.trayIconSize
    height: Theme.barHeight

    Image {
        id: icon

        anchors.centerIn: parent
        width: Theme.trayIconSize
        height: Theme.trayIconSize
        source: Tray.iconFor(root.item)

        sourceSize.width: Theme.trayIconSize * 2
        sourceSize.height: Theme.trayIconSize * 2

        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: true

        // Passive is dimmed, not hidden, or the app looks shut.
        opacity: Tray.needsAttention(root.item) ? 1.0
               : hover.hovered ? 1.0
               : Tray.isPassive(root.item) ? 0.5
               : 0.8

        Behavior on opacity {
            NumberAnimation { duration: Theme.animDuration }
        }
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: -3
        width: 4
        height: 4
        radius: 2
        color: Theme.attention
        visible: Tray.needsAttention(root.item)
    }

    HoverHandler { id: hover }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: mouse => {
            if (mouse.button === Qt.LeftButton) {
                // onlyMenu items have no primary action, so the menu is the left click.
                if (root.item.onlyMenu && root.item.hasMenu) {
                    root.menuRequested(root.x);
                } else {
                    root.item.activate();
                }
            } else if (mouse.button === Qt.MiddleButton) {
                root.item.secondaryActivate();
            } else if (root.item.hasMenu) {
                root.menuRequested(root.x);
            }
        }

        onWheel: wheel => {
            const dy = wheel.angleDelta.y;
            if (dy !== 0) root.item.scroll(dy > 0 ? -1 : 1, false);
        }
    }
}
