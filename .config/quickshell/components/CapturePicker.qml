// Pick what to record. Opened by `hypr-screenrecord menu`.

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.theme
import qs.services

PanelWindow {
    id: root

    visible: Capture.pickerOpen

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    exclusiveZone: 0
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-capture-picker"

    // Exclusive so Escape and the digits reach the panel.
    WlrLayershell.keyboardFocus: Capture.pickerOpen
        ? WlrKeyboardFocus.Exclusive
        : WlrKeyboardFocus.None

    // Dim what is behind; a click outside the panel closes.
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.5

        MouseArea {
            anchors.fill: parent
            onClicked: Capture.close()
        }
    }

    Rectangle {
        id: panel

        anchors.centerIn: parent

        width: Math.min(parent.width - 120, 560)
        implicitHeight: content.implicitHeight + Theme.popoutPadding * 2

        radius: Theme.popoutRadius
        color: Theme.popoutBg
        border.width: Theme.popoutBorder
        border.color: Theme.popoutEdge

        // Swallow clicks so they do not reach the dimmer behind.
        MouseArea {
            anchors.fill: parent
        }

        Column {
            id: content

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Theme.popoutPadding
            spacing: Theme.popoutGap

            Item {
                width: parent.width
                height: 24

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "RECORD"
                    color: Theme.overlay0
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.popoutBodySize - 2
                    font.letterSpacing: 0.5
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Esc to close"
                    color: Theme.overlay0
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.popoutBodySize - 3
                }
            }

            Row {
                id: tiles

                width: parent.width
                spacing: Theme.popoutGap

                readonly property real tileWidth:
                    (width - spacing * (Capture.modes.length - 1)) / Capture.modes.length

                Repeater {
                    model: Capture.modes

                    Rectangle {
                        required property var modelData
                        required property int index

                        width: tiles.tileWidth
                        height: 132

                        radius: Theme.popoutCardRadius
                        color: tileHover.hovered ? Theme.popoutCard : "transparent"
                        border.width: 1
                        border.color: tileHover.hovered ? Theme.mauve : Theme.popoutEdge

                        Behavior on color {
                            ColorAnimation { duration: Theme.animDuration }
                        }
                        Behavior on border.color {
                            ColorAnimation { duration: Theme.animDuration }
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: Theme.glyph(modelData.glyph)
                                color: tileHover.hovered ? Theme.mauve : Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: 40
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.label
                                color: tileHover.hovered ? Theme.mauve : Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.popoutBodySize + 1
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.detail
                                color: Theme.subtext0
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.popoutBodySize - 3
                            }
                        }

                        Text {
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 8
                            text: (index + 1)
                            color: Theme.overlay0
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.popoutBodySize - 2
                        }

                        HoverHandler { id: tileHover }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Capture.record(modelData.mode)
                        }
                    }
                }
            }
        }

        focus: Capture.pickerOpen

        Keys.onEscapePressed: Capture.close()

        Keys.onPressed: event => {
            const i = event.key - Qt.Key_1;
            if (i >= 0 && i < Capture.modes.length) {
                Capture.record(Capture.modes[i].mode);
                event.accepted = true;
            }
        }
    }
}
