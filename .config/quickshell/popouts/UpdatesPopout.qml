// ---------------- pending updates ----------------
// Right-click list. Left click on the bar module runs the upgrade instead.

import QtQuick
import Quickshell
import qs.theme
import qs.components
import qs.services

Popout {
    id: root

    contentWidth: 420

    readonly property int maxListHeight: 360

    contentHeight: Theme.popoutPadding * 2
                 + header.height
                 + Theme.popoutGap
                 + Math.max(22, Math.min(root.maxListHeight, body.implicitHeight))
                 + Theme.popoutGap
                 + footer.height

    function sinceText(when) {
        if (!when) return "not yet checked";
        const secs = Math.floor((Date.now() - when.getTime()) / 1000);
        if (secs < 60) return "checked just now";
        const mins = Math.floor(secs / 60);
        if (mins < 60) return "checked " + mins + " min ago";
        const hrs = Math.floor(mins / 60);
        return "checked " + hrs + (hrs === 1 ? " hour ago" : " hours ago");
    }

    Column {
        anchors.fill: parent
        anchors.margins: Theme.popoutPadding
        spacing: Theme.popoutGap

        // ---- header ----
        Item {
            id: header

            width: parent.width
            height: 26

            Text {
                id: title

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "UPDATES"
                color: Theme.overlay0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize - 2
                font.letterSpacing: 0.5
            }

            Text {
                anchors.left: title.right
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: Updates.total
                color: Theme.updatesColour(Updates.total)
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize - 2
            }

            // Re-check. Fixed box with an exact hit area, not negative margins.
            Item {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 24
                height: 24

                Text {
                    id: refreshGlyph

                    anchors.centerIn: parent
                    text: Theme.glyph("refresh")
                    color: Updates.busy
                        ? Theme.overlay0
                        : (refreshHover.hovered ? Theme.text : Theme.subtext0)
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.popoutBodySize

                    Behavior on color {
                        ColorAnimation { duration: Theme.animDuration }
                    }

                    // Reset via the id: `target` is null in the `on rotation` form.
                    RotationAnimation on rotation {
                        running: Updates.busy
                        from: 0
                        to: 360
                        duration: 900
                        loops: Animation.Infinite
                        onStopped: refreshGlyph.rotation = 0
                    }
                }

                HoverHandler { id: refreshHover }

                MouseArea {
                    anchors.fill: parent
                    enabled: !Updates.busy
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Updates.refresh()
                }
            }
        }

        // ---- the list ----
        Flickable {
            width: parent.width
            height: Math.max(22, Math.min(root.maxListHeight, body.implicitHeight))
            contentHeight: body.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            interactive: body.implicitHeight > height

            Column {
                id: body

                width: parent.width
                spacing: 2

                // Failed is not up to date: the module hides at zero either way.
                Text {
                    width: parent.width
                    visible: Updates.repoFailed
                    text: "Could not check for updates."
                    color: Theme.attention
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.popoutBodySize
                    wrapMode: Text.WordWrap
                }

                Text {
                    width: parent.width
                    visible: !Updates.repoFailed && Updates.total === 0
                    text: "Everything is up to date."
                    color: Theme.overlay0
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.popoutBodySize
                }

                SectionLabel {
                    label: "REPOSITORIES"
                    count: Updates.repoCount
                    visible: Updates.repoCount > 0
                }

                Repeater {
                    model: Updates.repoPackages

                    PackageRow {
                        required property var modelData
                        pkg: modelData
                        width: body.width
                    }
                }

                SectionLabel {
                    label: "AUR"
                    count: Updates.aurCount
                    visible: Updates.aurAvailable && Updates.aurCount > 0
                }

                Repeater {
                    model: Updates.aurAvailable ? Updates.aurPackages : []

                    PackageRow {
                        required property var modelData
                        pkg: modelData
                        width: body.width
                    }
                }

            }
        }

        // ---- footer ----
        Item {
            id: footer

            width: parent.width
            height: 16

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: root.sinceText(Updates.lastChecked)
                color: Theme.overlay0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize - 3
            }

            // AUR helper, or none. In the footer so the scroll cap cannot hide it.
            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: Updates.aurAvailable
                    ? Updates.aurHelper
                    : "no AUR helper"
                color: Theme.overlay0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize - 3
            }
        }
    }

    component SectionLabel: Item {
        id: section

        required property string label
        property int count: 0

        width: parent ? parent.width : 0
        height: 24

        Text {
            id: sectionText

            anchors.left: parent.left
            anchors.bottom: parent.bottom
            text: section.label
            color: Theme.overlay0
            font.family: Theme.fontFamily
            font.pixelSize: Theme.popoutBodySize - 3
            font.letterSpacing: 0.5
        }

        Text {
            anchors.left: sectionText.right
            anchors.leftMargin: 6
            anchors.baseline: sectionText.baseline
            text: section.count
            color: Theme.subtext0
            font.family: Theme.fontFamily
            font.pixelSize: Theme.popoutBodySize - 3
        }
    }

    // The name elides, never the version pair.
    component PackageRow: Rectangle {
        id: row

        required property var pkg

        height: 24
        radius: Theme.popoutCardRadius
        color: rowHover.hovered ? Theme.surface0 : "transparent"

        Behavior on color {
            ColorAnimation { duration: Theme.animDuration }
        }

        HoverHandler { id: rowHover }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 6
            anchors.right: versions.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: row.pkg ? row.pkg.name : ""
            color: Theme.text
            elide: Text.ElideRight
            font.family: Theme.fontFamily
            font.pixelSize: Theme.popoutBodySize - 1
        }

        Text {
            id: versions

            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            visible: !!row.pkg && row.pkg.to !== ""
            text: row.pkg ? row.pkg.from + " → " + row.pkg.to : ""
            color: Theme.overlay0
            font.family: Theme.fontFamily
            font.pixelSize: Theme.popoutBodySize - 3
        }
    }
}
