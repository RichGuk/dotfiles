// ---------------- battery popout ----------------
// Height is measured, not summed: the peripheral list and throttling notice come and go.

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.UPower
import qs.theme
import qs.components
import qs.services

Popout {
    id: root

    contentWidth: 320
    contentHeight: batCol.implicitHeight + Theme.popoutPadding * 2

    Column {
        id: batCol

        anchors.fill: parent
        anchors.margins: Theme.popoutPadding
        spacing: Theme.popoutGap

        // ---- the reading ----
        Item {
            width: parent.width
            height: 46

            Text {
                id: batIcon

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 34
                text: Battery.glyph
                color: Battery.color
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize + 14
            }

            Text {
                anchors.left: batIcon.right
                anchors.leftMargin: Theme.popoutGap - 6
                anchors.top: parent.top
                text: Battery.percent + "%"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutTitleSize
            }

            Text {
                anchors.left: batIcon.right
                anchors.leftMargin: Theme.popoutGap - 6
                anchors.bottom: parent.bottom
                text: Battery.statusLine
                color: Theme.overlay0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize - 1
            }

            // Mains indicator, independent of charge state: a full battery on
            // mains is neither charging nor discharging.
            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: Battery.onAc
                text: Theme.glyph("powerPlug")
                color: Theme.mauve
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize + 3
            }
        }

        // ---- detail ----
        Column {
            width: parent.width
            spacing: 0

            Text {
                text: "DETAIL"
                color: Theme.overlay0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize - 2
                font.letterSpacing: 0.5
                bottomPadding: 6
            }

            // UPower reports a magnitude; the state carries the direction.
            BatteryRow {
                width: parent.width
                glyph: "speedometer"
                label: Battery.charging ? "charging at" : "drawing"
                value: Battery.watts > 0
                    ? Battery.watts.toFixed(1) + " W" : "—"
                visible: Battery.watts > 0
            }

            BatteryRow {
                width: parent.width
                glyph: "battery"
                label: "capacity"
                value: Battery.energyCapacity > 0
                    ? Battery.energy.toFixed(1) + " / "
                      + Battery.energyCapacity.toFixed(1) + " Wh"
                    : "—"
                visible: Battery.energyCapacity > 0
            }

            BatteryRow {
                width: parent.width
                glyph: "heart"
                label: "health"
                value: Battery.health + "%"
                valueColor: Battery.health < 80 ? Theme.warning : Theme.text
                visible: Battery.healthKnown
            }
        }

        // ---- power profile ----
        Column {
            width: parent.width
            spacing: 0

            Text {
                text: "POWER PROFILE"
                color: Theme.overlay0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize - 2
                font.letterSpacing: 0.5
                bottomPadding: 4
            }

            Repeater {
                model: Battery.profileOptions

                Item {
                    required property var modelData

                    width: parent.width
                    height: Theme.popoutRowHeight

                    readonly property bool isCurrent:
                        Battery.profile === modelData.value

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.popoutCardRadius
                        color: profHover.hovered
                            ? Theme.popoutCard : "transparent"

                        Behavior on color {
                            ColorAnimation { duration: Theme.animDuration }
                        }
                    }

                    HoverHandler { id: profHover }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Battery.setProfile(modelData.value)
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 6
                        height: 6
                        radius: 3
                        color: Theme.mauve
                        visible: parent.isCurrent
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 22
                        anchors.verticalCenter: parent.verticalCenter
                        width: 20
                        text: Theme.glyph(modelData.glyph)
                        color: parent.isCurrent ? Theme.mauve : Theme.overlay0
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.popoutBodySize
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 48
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.label
                        color: parent.isCurrent ? Theme.text : Theme.subtext1
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.popoutBodySize
                    }
                }
            }

            Text {
                width: parent.width
                visible: Battery.degradedReason !== ""
                text: Theme.glyph("alert") + "  " + Battery.degradedReason
                color: Theme.warning
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize - 1
                topPadding: 6
            }
        }

        // ---- peripherals ----
        Column {
            width: parent.width
            spacing: 0
            visible: Battery.peripherals.length > 0

            Text {
                text: "DEVICES"
                color: Theme.overlay0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize - 2
                font.letterSpacing: 0.5
                bottomPadding: 6
            }

            Repeater {
                model: Battery.peripherals

                BatteryRow {
                    required property var modelData

                    width: parent.width
                    glyphText: Battery.peripheralGlyph(modelData.type)
                    label: Battery.peripheralLabel(modelData)
                    value: Battery.peripheralPercent(modelData) + "%"
                    valueColor: Battery.peripheralPercent(modelData) <= Theme.batteryWarnAt
                        ? Theme.warning : Theme.text
                }
            }
        }
    }

    component BatteryRow: Item {
        property string glyph: ""
        // A literal character; set instead of `glyph` (a Theme glyph name).
        property string glyphText: ""
        property string label: ""
        property string value: ""
        property color valueColor: Theme.text

        height: visible ? 24 : 0

        Text {
            id: rowIcon

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 22
            text: parent.glyphText !== ""
                ? parent.glyphText
                : (parent.glyph !== "" ? Theme.glyph(parent.glyph) : "")
            color: Theme.overlay0
            font.family: Theme.fontFamily
            font.pixelSize: Theme.popoutBodySize - 1
        }

        Text {
            anchors.left: rowIcon.right
            anchors.right: rowValue.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: parent.label
            elide: Text.ElideRight
            color: Theme.subtext1
            font.family: Theme.fontFamily
            font.pixelSize: Theme.popoutBodySize - 1
        }

        Text {
            id: rowValue

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: parent.value
            color: parent.valueColor
            font.family: Theme.fontFamily
            font.pixelSize: Theme.popoutBodySize - 1
        }
    }
}
