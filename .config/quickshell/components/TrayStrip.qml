// The tray: a chevron, pinned items, and a drawer holding the rest.

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import qs.theme
import qs.services

Item {
    id: root

    // The menu is a popout, and popouts are owned by the shell.
    signal menuRequested(var item, real x)

    property bool open: false

    visible: Tray.count > 0

    implicitWidth: visible ? strip.width : 0
    height: Theme.barHeight

    onVisibleChanged: if (!visible) root.open = false

    Row {
        id: strip

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.trayItemSpacing

        // ---- the expander ----
        // Bar height, not icon height: a Text's box includes ascent/descent, so a
        // small box puts the ink off centre.
        Item {
            width: Theme.trayIconSize
            height: Theme.barHeight
            visible: Tray.drawerItems.length > 0

            Text {
                anchors.centerIn: parent
                // The right-anchored group grows LEFTWARD, despite the drawer being the next
                // sibling. So collapsed points left, open points right.
                text: Theme.glyph(root.open ? "chevronRight" : "chevronLeft")
                color: chevHover.hovered ? Theme.barText : Theme.barDim
                font.family: Theme.fontFamily

                // md-chevron draws small for its em box, hence bigger than the bar font.
                font.pixelSize: Theme.fontSize + 5

                Behavior on color {
                    ColorAnimation { duration: Theme.animDuration }
                }
            }

            HoverHandler { id: chevHover }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: root.open = !root.open
            }
        }

        // ---- the drawer ----
        // Width-animated and clipped so items slide out from behind the chevron.
        Item {
            id: drawer

            height: Theme.barHeight
            clip: true

            width: root.open ? drawerRow.width : 0

            Behavior on width {
                NumberAnimation {
                    duration: Theme.trayDrawerDuration
                    easing.type: Theme.animEasing
                }
            }

            Row {
                id: drawerRow

                // Anchored right so items emerge from the chevron's side.
                anchors.right: parent.right
                spacing: Theme.trayItemSpacing

                Repeater {
                    model: Tray.drawerItems

                    TrayIcon {
                        required property var modelData
                        item: modelData
                        onMenuRequested: x => root.menuRequested(modelData, x)
                    }
                }
            }
        }

        // ---- pinned items ----
        Row {
            spacing: Theme.trayItemSpacing

            Repeater {
                model: Tray.pinnedItems

                TrayIcon {
                    required property var modelData
                    item: modelData
                    onMenuRequested: x => root.menuRequested(modelData, x)
                }
            }
        }
    }
}
