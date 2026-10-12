// ---------------- now-playing popout ----------------

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import qs.theme
import qs.components
import qs.services

Popout {
    id: root

    readonly property int artSize: 96

    // Some players (Firefox) report no length; Media trusts lengthSupported,
    // not a non-zero test. Unmeasurable tracks hide the whole progress readout.
    readonly property bool measurable:
        !!Media.track && Media.track.lengthSec > 0

    // Everything in the row except the metadata column. Must match the
    // column's width expression below.
    readonly property int chromeWidth: Theme.popoutPadding * 2
                                     + root.artSize + Theme.popoutGap
                                     + Theme.popoutBadgeSize + Theme.popoutGap

    // Bar module width plus chrome, not just padding, or the title elides
    // while the bar shows it in full.
    contentWidth: Math.max(Theme.popoutMinWidth,
        Math.min(Theme.popoutMaxWidth,
                 root.anchorItem.width + root.chromeWidth))
    contentHeight: 150

    Behavior on contentWidth {
        NumberAnimation {
            duration: Theme.animDuration
            easing.type: Theme.animEasing
        }
    }

    // Source badge. iconPath's `true` returns "" for a missing icon rather
    // than a broken path, which is what lets the glyph fallback below show.
    Image {
        id: sourceBadge

        anchors {
            top: parent.top
            right: parent.right
            topMargin: Theme.popoutPadding
            rightMargin: Theme.popoutPadding
        }

        width: Theme.popoutBadgeSize
        height: Theme.popoutBadgeSize
        asynchronous: true
        fillMode: Image.PreserveAspectFit
        visible: status === Image.Ready

        source: Media.track && Media.track.desktopEntry
            ? Quickshell.iconPath(Media.track.desktopEntry, true)
            : ""
    }

    Text {
        anchors.fill: sourceBadge
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        visible: !!Media.track && !sourceBadge.visible
        text: Theme.glyph("music")
        color: Theme.overlay0
        font.family: Theme.fontFamily
        font.pixelSize: Theme.popoutBadgeSize - 4
    }

            Row {
                anchors.fill: parent
                anchors.margins: Theme.popoutPadding
                spacing: Theme.popoutGap

                // ---- album art ----
                Rectangle {
                    width: root.artSize
                    height: root.artSize
                    radius: Theme.popoutCardRadius
                    color: Theme.popoutCard
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        id: albumArt

                        anchors.fill: parent
                        source: Media.track && Media.track.artUrl
                            ? Media.track.artUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: status === Image.Ready

                        layer.enabled: true
                        layer.effect: MultiEffect {
                            maskEnabled: true
                            maskSource: albumArtMask
                        }
                    }

                    // Mask so the art takes the card's corners.
                    Rectangle {
                        id: albumArtMask
                        anchors.fill: parent
                        radius: Theme.popoutCardRadius
                        visible: false
                        layer.enabled: true
                    }

                    // Not glyph("album"): U+F00A5 draws binoculars, so that key is gone.
                    Text {
                        anchors.centerIn: parent
                        visible: !albumArt.visible
                        text: Theme.glyph("music")
                        color: Theme.overlay0
                        font.family: Theme.fontFamily
                        font.pixelSize: 36
                    }
                }

                // ---- metadata, progress, transport ----
                // Width leaves room for the corner badge; see chromeWidth.
                Column {
                    width: parent.width - root.artSize - Theme.popoutGap
                           - Theme.popoutBadgeSize - Theme.popoutGap
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3

                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: Media.track ? Media.track.title : "Nothing playing"
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.popoutTitleSize
                    }

                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        visible: !!Media.track
                        text: Media.track ? "by " + Media.track.artist : ""
                        color: Theme.subtext0
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.popoutBodySize
                    }

                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        visible: !!Media.track
                        text: Media.track ? "on " + Media.track.album : ""
                        color: Theme.overlay0
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.popoutBodySize
                    }

                    // Progress: an indicator, not a seek control.
                    Rectangle {
                        visible: root.measurable
                        width: parent.width
                        height: 4
                        radius: 2
                        color: Theme.popoutCard

                        Rectangle {
                            height: parent.height
                            radius: parent.radius
                            color: Theme.mauve
                            // Clamped: position can overrun a stale length after a track change.
                            width: root.measurable
                                ? parent.width * Math.min(1, Media.positionSec
                                                             / Media.track.lengthSec)
                                : 0

                            Behavior on width {
                                NumberAnimation { duration: 400 }
                            }
                        }
                    }

                    // Elapsed, transport, total.
                    Item {
                        width: parent.width
                        // Follows the glyph size: a fixed height clips a bigger glyph.
                        height: Theme.popoutTransportSize + 8

                        Text {
                            visible: root.measurable
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: Media.formatDuration(Media.positionSec)
                            color: Theme.subtext0
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.popoutBodySize
                        }

                        Row {
                            anchors.centerIn: parent
                            spacing: Theme.popoutTransportSpacing

                            Repeater {
                                model: [
                                    { name: "prev",  action: "previous" },
                                    { name: Media.track && Media.track.playing
                                        ? "pause" : "play", action: "toggle" },
                                    { name: "next",  action: "next" }
                                ]

                                Text {
                                    required property var modelData

                                    // Not `enabled`: that is Item's own and changes input handling.
                                    readonly property bool actionAvailable:
                                        modelData.action === "next"     ? Media.canGoNext
                                      : modelData.action === "previous" ? Media.canGoPrevious
                                      :                                   Media.canToggle

                                    text: Theme.glyph(modelData.name)
                                    color: !actionAvailable  ? Theme.overlay0
                                         : transport.hovered ? Theme.text
                                         :                     Theme.subtext0
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.popoutTransportSize

                                    Behavior on color {
                                        ColorAnimation { duration: Theme.animDuration }
                                    }

                                    HoverHandler { id: transport }

                                    MouseArea {
                                        anchors.fill: parent
                                        anchors.margins: -Theme.popoutTransportHit
                                        enabled: parent.actionAvailable
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (modelData.action === "toggle")        Media.togglePlaying();
                                            else if (modelData.action === "next")     Media.next();
                                            else if (modelData.action === "previous") Media.previous();
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            visible: root.measurable
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.measurable
                                ? Media.formatDuration(Media.track.lengthSec) : ""
                            color: Theme.subtext0
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.popoutBodySize
                        }
                    }
                }
            }
}
