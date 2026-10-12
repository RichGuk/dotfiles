// ---------------- tray menu ----------------
// Rendered in QML via QsMenuOpener, not QsMenuEntry.display(): that needs a
// QApplication shell, which this is not, and submenus come up empty.
// Submenus drill down rather than fly out, so nothing opens off-screen.

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import qs.theme
import qs.components
import qs.services

Popout {
    id: root

    // The item whose menu this is. Null when nothing is open.
    property var trayItem: null

    contentWidth: 250
    contentHeight: menuCol.implicitHeight + Theme.popoutPadding

    // Submenu handles descended into. Empty means the top level.
    property var stack: []

    onShownChanged: if (!shown) root.stack = [];

    onTrayItemChanged: root.stack = []

    readonly property var currentHandle:
        root.stack.length > 0
            ? root.stack[root.stack.length - 1].handle
            : (root.trayItem ? root.trayItem.menu : null)

    readonly property string currentTitle:
        root.stack.length > 0
            ? root.stack[root.stack.length - 1].title
            : Tray.label(root.trayItem)

    // One opener, repointed as we descend: one per level leaks D-Bus subscriptions.
    QsMenuOpener {
        id: opener
        menu: root.currentHandle
    }

    Column {
        id: menuCol

        anchors.fill: parent
        anchors.margins: Theme.popoutPadding
        anchors.bottomMargin: 0
        spacing: 0

        // ---- header / back row ----
        Item {
            width: parent.width
            height: 26

            Text {
                id: backGlyph

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: root.stack.length > 0 ? 18 : 0
                visible: width > 0
                text: Theme.glyph("chevronLeft")
                color: backHover.hovered ? Theme.text : Theme.overlay0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize
            }

            Text {
                anchors.left: backGlyph.right
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: root.currentTitle
                elide: Text.ElideRight
                color: Theme.overlay0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize - 2
                font.letterSpacing: 0.5
            }

            HoverHandler { id: backHover }

            MouseArea {
                anchors.fill: parent
                enabled: root.stack.length > 0
                cursorShape: Qt.PointingHandCursor
                onClicked: root.stack = root.stack.slice(0, -1)
            }
        }

        Repeater {
            model: opener.children ? opener.children.values : []

            Item {
                required property var modelData

                width: menuCol.width
                height: modelData && modelData.isSeparator
                    ? 9 : Theme.popoutRowHeight

                // ---- separator ----
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width - 8
                    height: 1
                    color: Theme.surface1
                    visible: modelData && modelData.isSeparator
                }

                // ---- entry ----
                Rectangle {
                    anchors.fill: parent
                    anchors.leftMargin: -4
                    anchors.rightMargin: -4
                    radius: Theme.popoutCardRadius
                    visible: modelData && !modelData.isSeparator
                    color: rowHover.hovered && modelData.enabled
                        ? Theme.popoutCard : "transparent"

                    Behavior on color {
                        ColorAnimation { duration: Theme.animDuration }
                    }
                }

                HoverHandler { id: rowHover }

                MouseArea {
                    anchors.fill: parent
                    enabled: modelData && !modelData.isSeparator
                             && modelData.enabled
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (modelData.hasChildren) {
                            // A QsMenuEntry is itself a QsMenuHandle.
                            root.stack = root.stack.concat([{
                                handle: modelData,
                                title: modelData.text
                            }]);
                            return;
                        }
                        // `triggered` is a signal; emitting it activates. No trigger() exists.
                        modelData.triggered();
                        root.dismissed();
                    }
                }

                Text {
                    id: check

                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: modelData && modelData.buttonType !== QsMenuButtonType.None
                        ? 20 : 0
                    visible: width > 0
                    text: modelData && modelData.checkState === Qt.Checked
                        ? Theme.glyph("check") : ""
                    color: Theme.mauve
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.popoutBodySize - 2
                }

                Text {
                    anchors.left: check.right
                    anchors.leftMargin: 4
                    anchors.right: submenuGlyph.left
                    anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    visible: modelData && !modelData.isSeparator
                    text: modelData ? modelData.text : ""
                    elide: Text.ElideRight
                    color: modelData && modelData.enabled
                        ? Theme.text : Theme.overlay0
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.popoutBodySize
                }

                Text {
                    id: submenuGlyph

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: modelData && modelData.hasChildren ? 16 : 0
                    visible: width > 0
                    text: Theme.glyph("chevronRight")
                    color: Theme.overlay0
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.popoutBodySize - 2
                }
            }
        }

        // An app can advertise a menu and then publish nothing in it.
        Text {
            width: parent.width
            visible: !opener.children || opener.children.values.length === 0
            text: "No menu items"
            color: Theme.overlay0
            font.family: Theme.fontFamily
            font.pixelSize: Theme.popoutBodySize - 1
            topPadding: 4
            bottomPadding: 4
        }
    }
}
