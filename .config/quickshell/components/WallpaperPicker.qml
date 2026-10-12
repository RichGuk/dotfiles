// Pick a wallpaper from a grid of thumbnails. Applying is instant.

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.theme
import qs.services

PanelWindow {
    id: root

    visible: Wallpaper.pickerOpen

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    exclusiveZone: 0
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-wallpaper-picker"

    // Exclusive so Escape reaches the grid.
    WlrLayershell.keyboardFocus: Wallpaper.pickerOpen
        ? WlrKeyboardFocus.Exclusive
        : WlrKeyboardFocus.None

    // Dim what is behind; a click outside the panel closes.
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.5

        MouseArea {
            anchors.fill: parent
            onClicked: Wallpaper.closePicker()
        }
    }

    Rectangle {
        id: panel

        anchors.centerIn: parent

        width: Math.min(parent.width - 120, 980)
        height: Math.min(parent.height - 120, 640)

        radius: Theme.popoutRadius
        color: Theme.popoutBg
        border.width: Theme.popoutBorder
        border.color: Theme.popoutEdge

        // Swallow clicks so they do not reach the dimmer behind.
        MouseArea {
            anchors.fill: parent
        }

        Column {
            anchors.fill: parent
            anchors.margins: Theme.popoutPadding
            spacing: Theme.popoutGap

            Item {
                id: header

                width: parent.width
                height: 24

                Text {
                    id: title

                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "WALLPAPER"
                    color: Theme.overlay0
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.popoutBodySize - 2
                    font.letterSpacing: 0.5
                }

                Text {
                    anchors.left: title.right
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: Wallpaper.available.length
                    color: Theme.mauve
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.popoutBodySize - 2
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

            Text {
                width: parent.width
                visible: Wallpaper.available.length === 0 && !Wallpaper.scanning
                text: "No wallpapers found.\n\nPut images in ~/Pictures/Wallpapers "
                    + "— Hyprland's bundled ones are only used as a fallback."
                color: Theme.subtext0
                wrapMode: Text.WordWrap
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize
            }

            GridView {
                id: grid

                width: parent.width
                height: parent.height - header.height - Theme.popoutGap
                visible: Wallpaper.available.length > 0

                clip: true
                cellWidth: Math.floor(width / Math.max(1, Math.floor(width / 300)))
                cellHeight: Math.round(cellWidth * 0.62)

                model: Wallpaper.available
                boundsBehavior: Flickable.StopAtBounds

                delegate: Item {
                    id: cell

                    required property var modelData

                    width: grid.cellWidth
                    height: grid.cellHeight

                    readonly property bool isCurrent: modelData === Wallpaper.path

                    Rectangle {
                        id: card

                        anchors.fill: parent
                        anchors.margins: 6

                        radius: Theme.popoutCardRadius
                        color: Theme.popoutCard
                        clip: true

                        Image {
                            anchors.fill: parent
                            source: "file://" + modelData
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true

                            // Decode at thumbnail size, or every cell holds a full 4K image.
                            sourceSize.width: grid.cellWidth
                            sourceSize.height: grid.cellHeight

                            opacity: status === Image.Ready ? 1 : 0
                            Behavior on opacity {
                                NumberAnimation { duration: Theme.animDuration }
                            }
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 24
                            color: "#cc11111b"

                            Text {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                verticalAlignment: Text.AlignVCenter
                                text: modelData.split("/").pop()
                                color: Theme.text
                                elide: Text.ElideMiddle
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.popoutBodySize - 3
                            }
                        }

                        // Drawn after the thumbnail: a Rectangle paints its border underneath its
                        // own children, so a border on the card is hidden by the Image.
                        Rectangle {
                            anchors.fill: parent
                            radius: card.radius
                            color: "transparent"

                            border.width: cell.isCurrent
                                ? 3 : (cellHover.hovered ? 1 : 0)
                            border.color: cell.isCurrent
                                ? Theme.mauve : Theme.popoutEdge

                            Behavior on border.color {
                                ColorAnimation { duration: Theme.animDuration }
                            }
                        }

                        Rectangle {
                            visible: cell.isCurrent

                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 8

                            width: 22
                            height: 22
                            radius: width / 2
                            color: Theme.mauve

                            Text {
                                anchors.centerIn: parent
                                text: Theme.glyph("check")
                                color: Theme.popoutBg
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.popoutBodySize
                            }
                        }

                        HoverHandler { id: cellHover }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Wallpaper.setWallpaper(modelData)
                        }
                    }
                }
            }
        }

        focus: Wallpaper.pickerOpen
        Keys.onEscapePressed: Wallpaper.closePicker()
    }
}
