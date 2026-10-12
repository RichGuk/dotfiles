// ---------------- display popout ----------------
// One SCALE control acting on the focused monitor, then the monitor list.

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import qs.theme
import qs.components
import qs.services

Popout {
    id: root

    readonly property var scaleTarget: Display.focusedMonitor

    contentWidth: 340
    // Summed: keep in step with the item heights below.
    contentHeight: Theme.popoutPadding * 2
                 + 26                                    // title
                 + Theme.popoutGap + 44                   // scale
                 + Theme.popoutGap + 18                   // heading
                 + Display.monitors.length * 40           // list

    Column {
        anchors.fill: parent
        anchors.margins: Theme.popoutPadding
        spacing: Theme.popoutGap

        // ---- title ----
        Item {
            width: parent.width
            height: 26

            Text {
                id: dispIcon

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: Theme.glyph(Display.monitors.length > 1
                    ? "displays" : "display")
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize + 4
            }

            Text {
                anchors.left: dispIcon.right
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: "Display"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutTitleSize
            }
        }

        // ---- scale, for the focused monitor ----
        Item {
            width: parent.width
            height: 44

            Text {
                id: scaleLabel

                anchors.left: parent.left
                anchors.top: parent.top
                text: "SCALE"
                color: Theme.overlay0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize - 2
                font.letterSpacing: 0.5
            }

            Text {
                anchors.right: parent.right
                anchors.baseline: scaleLabel.baseline
                text: root.scaleTarget
                    ? root.scaleTarget.name : ""
                color: Theme.subtext0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize - 2
            }

            Row {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                spacing: 6

                Repeater {
                    model: root.scaleTarget
                        ? Display.validScales(
                            root.scaleTarget.width,
                            root.scaleTarget.height)
                        : []

                    Rectangle {
                        required property real modelData

                        // Tolerant: Hyprland's 1/120 rounding returns 1.6 as 1.5999999.
                        readonly property bool isCurrent:
                            !!root.scaleTarget
                            && Math.abs(modelData
                                 - root.scaleTarget.scale) < 0.01

                        width: 46
                        height: 26
                        radius: Theme.popoutCardRadius
                        color: isCurrent ? Theme.mauve
                             : chipHover.hovered ? Theme.popoutCard
                             : "transparent"
                        border.width: isCurrent ? 0 : 1
                        border.color: Theme.surface0

                        Behavior on color {
                            ColorAnimation { duration: Theme.animDuration }
                        }

                        HoverHandler { id: chipHover }

                        Text {
                            anchors.centerIn: parent
                            text: modelData + "x"
                            color: parent.isCurrent
                                ? Theme.crust : Theme.subtext1
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.popoutBodySize - 1
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Display.setScale(
                                root.scaleTarget, modelData)
                        }
                    }
                }
            }
        }

        // ---- the monitors themselves ----
        Column {
            width: parent.width
            spacing: 0

            Text {
                text: "DISPLAYS"
                color: Theme.overlay0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize - 2
                font.letterSpacing: 0.5
                bottomPadding: 4
            }

            Repeater {
                model: Display.monitors

                Item {
                    required property var modelData

                    width: parent.width
                    height: 40

                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 6
                        height: 6
                        radius: 3
                        color: Theme.mauve
                        visible: modelData.focused
                    }

                    Text {
                        id: rowName

                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.top: parent.top
                        anchors.topMargin: 2
                        text: modelData.name
                        color: modelData.focused
                            ? Theme.text : Theme.subtext1
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.popoutBodySize
                    }

                    Text {
                        anchors.left: rowName.right
                        anchors.leftMargin: 8
                        anchors.baseline: rowName.baseline
                        anchors.right: parent.right
                        text: modelData.description || ""
                        elide: Text.ElideRight
                        color: Theme.overlay0
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.popoutBodySize - 2
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 2
                        text: modelData.width + "x" + modelData.height
                            + (Display.refreshRate(modelData) > 0
                                ? "@" + Display.refreshRate(modelData) : "")
                            + "   → " + Display.logicalSize(modelData)
                            + " at " + modelData.scale + "x"
                        color: Theme.overlay0
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.popoutBodySize - 2
                    }
                }
            }
        }
    }
}
