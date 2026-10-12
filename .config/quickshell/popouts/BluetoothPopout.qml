// ---------------- bluetooth popout ----------------
// Connected, paired, in range. In-range stays empty until a scan, on purpose.

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import qs.theme
import qs.components
import qs.services

Popout {
    id: root

    contentWidth: 330
    contentHeight: btCol.implicitHeight + Theme.popoutPadding * 2

    onShownChanged: Bluetooth.detailsVisible = shown

    Column {
        id: btCol

        anchors.fill: parent
        anchors.margins: Theme.popoutPadding
        spacing: Theme.popoutGap

        // ---- adapter ----
        Item {
            width: parent.width
            height: 40

            Text {
                id: btIcon

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 26
                text: Theme.glyph(Bluetooth.glyphName)
                color: Bluetooth.powered ? Theme.text : Theme.overlay0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize + 6
            }

            Text {
                anchors.left: btIcon.right
                anchors.leftMargin: Theme.popoutGap - 4
                anchors.top: parent.top
                text: "Bluetooth"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize + 2
            }

            Text {
                anchors.left: btIcon.right
                anchors.leftMargin: Theme.popoutGap - 4
                anchors.bottom: parent.bottom
                text: Bluetooth.label
                color: Theme.overlay0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize - 1
            }

            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: Bluetooth.present
                width: 46
                height: 26
                radius: 13
                color: Bluetooth.powered ? Theme.mauve : Theme.surface0

                Behavior on color {
                    ColorAnimation { duration: Theme.animDuration }
                }

                Rectangle {
                    x: Bluetooth.powered ? parent.width - width - 3 : 3
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20
                    height: 20
                    radius: 10
                    color: Bluetooth.powered ? Theme.crust : Theme.overlay0

                    Behavior on x {
                        NumberAnimation {
                            duration: Theme.animDuration
                            easing.type: Theme.animEasing
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Bluetooth.setPowered(!Bluetooth.powered)
                }
            }
        }

        Text {
            width: parent.width
            visible: !Bluetooth.present
            text: "No bluetooth adapter"
            color: Theme.overlay0
            font.family: Theme.fontFamily
            font.pixelSize: Theme.popoutBodySize
        }

        // ---- connected ----
        Column {
            width: parent.width
            spacing: 0
            visible: Bluetooth.powered && Bluetooth.connectedDevices.length > 0

            BtHeading { text: "CONNECTED" }

            Repeater {
                model: Bluetooth.connectedDevices
                BtRow { required property var modelData; device: modelData }
            }
        }

        // ---- paired ----
        Column {
            width: parent.width
            spacing: 0
            visible: Bluetooth.powered && Bluetooth.pairedDevices.length > 0

            BtHeading { text: "PAIRED" }

            Repeater {
                model: Bluetooth.pairedDevices
                BtRow { required property var modelData; device: modelData }
            }
        }

        // ---- in range ----
        Column {
            width: parent.width
            spacing: 0
            visible: Bluetooth.powered

            Item {
                width: parent.width
                height: 22

                Text {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    text: "IN RANGE"
                    color: Theme.overlay0
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.popoutBodySize - 2
                    font.letterSpacing: 0.5
                }

                Text {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: -2
                    text: Theme.glyph("refresh")
                    color: scanHover.hovered ? Theme.text : Theme.overlay0
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.popoutBodySize

                    // Driven by BlueZ's discovering state, not the click.
                    RotationAnimation on rotation {
                        running: Bluetooth.discovering
                        from: 0; to: 360
                        duration: 900
                        loops: Animation.Infinite
                    }

                    HoverHandler { id: scanHover }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -8
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Bluetooth.scan()
                    }
                }
            }

            Text {
                width: parent.width
                visible: Bluetooth.availableDevices.length === 0
                text: Bluetooth.discovering ? "Scanning…" : "Scan to find devices"
                color: Theme.overlay0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize - 1
                bottomPadding: 4
            }

            Repeater {
                model: Bluetooth.availableDevices
                BtRow { required property var modelData; device: modelData }
            }
        }

        Text {
            width: parent.width
            visible: Bluetooth.lastError !== ""
            text: Theme.glyph("alert") + "  " + Bluetooth.lastError
            color: Theme.attention
            font.family: Theme.fontFamily
            font.pixelSize: Theme.popoutBodySize - 1
        }
    }

    component BtHeading: Text {
        width: parent.width
        color: Theme.overlay0
        font.family: Theme.fontFamily
        font.pixelSize: Theme.popoutBodySize - 2
        font.letterSpacing: 0.5
        bottomPadding: 4
    }

    // Click connects/disconnects/pairs; a paired device offers forget on hover.
    component BtRow: Item {
        id: row

        required property var device

        width: parent ? parent.width : 0
        height: Theme.popoutRowHeight

        readonly property bool busy: Bluetooth.busy === device.address

        Rectangle {
            anchors.fill: parent
            radius: Theme.popoutCardRadius
            color: rowHover.hovered ? Theme.popoutCard : "transparent"

            Behavior on color {
                ColorAnimation { duration: Theme.animDuration }
            }
        }

        HoverHandler { id: rowHover }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (row.device.connected) Bluetooth.disconnect(row.device.address);
                else if (row.device.paired) Bluetooth.connect(row.device.address);
                else Bluetooth.pair(row.device.address);
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: 6
            height: 6
            radius: 3
            color: Theme.mauve
            visible: row.device.connected
        }

        Text {
            id: devIcon

            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            width: 20
            text: Theme.glyph(Bluetooth.deviceGlyph(row.device.icon))
            color: row.device.connected ? Theme.mauve : Theme.overlay0
            font.family: Theme.fontFamily
            font.pixelSize: Theme.popoutBodySize
        }

        Text {
            anchors.left: devIcon.right
            anchors.leftMargin: 6
            anchors.right: rowRight.left
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            text: row.device.name
            elide: Text.ElideRight
            color: row.device.connected ? Theme.text : Theme.subtext1
            font.family: Theme.fontFamily
            font.pixelSize: Theme.popoutBodySize
        }

        Row {
            id: rowRight

            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            // No explicit width: `width: visible ? implicitWidth : 0` is a
            // binding loop, and Row already gives an invisible child no space.
            Text {
                visible: row.device.battery >= 0
                text: row.device.battery + "%"
                color: row.device.battery <= Theme.batteryWarnAt
                    ? Theme.warning : Theme.overlay0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize - 2
            }

            // Fixed box and the circle glyph pair (same bounding box), so the
            // hover swap does not shift.
            Text {
                width: 20
                height: 20
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter

                visible: row.device.paired
                text: Theme.glyph(rowHover.hovered ? "closeCircle" : "checkCircle")
                color: rowHover.hovered ? Theme.attention : Theme.overlay0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize - 2

                MouseArea {
                    anchors.fill: parent
                    z: 10
                    enabled: rowHover.hovered
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        mouse.accepted = true;
                        Bluetooth.forget(row.device.address);
                    }
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: Theme.popoutCardRadius
            color: Theme.crust
            opacity: row.busy ? 0.75 : 0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation { duration: Theme.animDuration }
            }

            Text {
                anchors.centerIn: parent
                text: row.device.paired ? "Connecting…" : "Pairing…"
                color: Theme.subtext1
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize - 1
            }
        }
    }
}
