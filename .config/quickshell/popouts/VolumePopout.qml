// ---------------- volume popout ----------------

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import qs.theme
import qs.components
import qs.services

Popout {
    id: root

    contentWidth: 300
    // Summed: keep in step with the item heights below.
    contentHeight: Theme.popoutPadding * 2
                 + 40                                  // output row
                 + Theme.popoutGap
                 + 40                                  // mic row
                 + (Audio.sinks.length > 1
                     ? Theme.popoutGap + 18
                       + Audio.sinks.length * Theme.popoutRowHeight
                     : 0)

    Column {
        anchors.fill: parent
        anchors.margins: Theme.popoutPadding
        spacing: Theme.popoutGap

        // ---- output ----
        Item {
            width: parent.width
            height: 40

            Text {
                id: outIcon

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 22
                text: Theme.glyph(Audio.glyphName)
                color: Audio.muted ? Theme.overlay0 : Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize + 3

                // Click to mute.
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Audio.toggleMute()
                }
            }

            Text {
                id: outPercent

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 42
                horizontalAlignment: Text.AlignRight
                text: Audio.volumePercent + "%"
                color: Audio.muted ? Theme.overlay0 : Theme.subtext1
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize
            }

            LevelSlider {
                anchors {
                    left: outIcon.right
                    leftMargin: Theme.popoutGap
                    right: outPercent.left
                    rightMargin: Theme.popoutGap
                    verticalCenter: parent.verticalCenter
                }
                value: Audio.volume
                opacity: Audio.muted ? 0.4 : 1
                onMoved: v => Audio.setVolume(v)

                Behavior on opacity {
                    NumberAnimation { duration: Theme.animDuration }
                }
            }
        }

        // ---- microphone ----
        Item {
            width: parent.width
            height: 40
            visible: Audio.sourceReady

            Text {
                id: micIcon

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 22
                text: Theme.glyph(Audio.sourceMuted ? "micOff" : "mic")
                color: Audio.sourceMuted ? Theme.overlay0 : Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize + 3

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Audio.toggleSourceMute()
                }
            }

            Text {
                id: micPercent

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 42
                horizontalAlignment: Text.AlignRight
                text: Math.round(Audio.sourceVolume * 100) + "%"
                color: Audio.sourceMuted ? Theme.overlay0 : Theme.subtext1
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize
            }

            LevelSlider {
                anchors {
                    left: micIcon.right
                    leftMargin: Theme.popoutGap
                    right: micPercent.left
                    rightMargin: Theme.popoutGap
                    verticalCenter: parent.verticalCenter
                }
                value: Audio.sourceVolume
                opacity: Audio.sourceMuted ? 0.4 : 1
                onMoved: v => Audio.setSourceVolume(v)

                Behavior on opacity {
                    NumberAnimation { duration: Theme.animDuration }
                }
            }
        }

        // ---- output devices (only when there is a choice) ----
        Column {
            width: parent.width
            spacing: 0
            visible: Audio.sinks.length > 1

            Text {
                text: "Output"
                color: Theme.overlay0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize - 1
                bottomPadding: 4
            }

            Repeater {
                model: Audio.sinks

                Item {
                    required property var modelData

                    width: parent.width
                    height: Theme.popoutRowHeight

                    readonly property bool isCurrent:
                        Audio.isCurrentSink(modelData)

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.popoutCardRadius
                        color: sinkHover.hovered
                            ? Theme.popoutCard : "transparent"

                        Behavior on color {
                            ColorAnimation { duration: Theme.animDuration }
                        }
                    }

                    HoverHandler { id: sinkHover }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Audio.setSink(modelData)
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 6
                        height: 6
                        radius: 3
                        color: Theme.mauve
                        visible: isCurrent
                    }

                    Text {
                        anchors {
                            left: parent.left
                            leftMargin: 22
                            right: parent.right
                            rightMargin: 8
                            verticalCenter: parent.verticalCenter
                        }
                        text: Audio.label(modelData)
                        elide: Text.ElideRight
                        color: isCurrent ? Theme.text : Theme.subtext1
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.popoutBodySize
                    }
                }
            }
        }
    }
}
