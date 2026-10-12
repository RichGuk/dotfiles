// ---------------- today's meetings ----------------
// Clicking a row opens its link.

import QtQuick
import Quickshell
import qs.theme
import qs.components
import qs.services

Popout {
    id: root

    contentWidth: 380

    readonly property int maxListHeight: 320

    contentHeight: Theme.popoutPadding * 2
                 + header.height
                 + Theme.popoutGap
                 + Math.max(22, Math.min(root.maxListHeight, body.implicitHeight))

    // "09:30". Local time, from the ISO string the script emits.
    function timeOf(iso) {
        if (!iso) return "";
        const d = new Date(iso);
        if (isNaN(d.getTime())) return "";
        return Qt.formatTime(d, "HH:mm");
    }

    Column {
        anchors.fill: parent
        anchors.margins: Theme.popoutPadding
        spacing: Theme.popoutGap

        Item {
            id: header

            width: parent.width
            height: 22

            Text {
                id: title

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: "TODAY"
                color: Theme.overlay0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize - 2
                font.letterSpacing: 0.5
            }

            Text {
                anchors.left: title.right
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                visible: Meeting.all.length > 0
                text: Meeting.all.length
                color: Theme.mauve
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize - 2
            }
        }

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

                // Distinct from "nothing today": the bar hides itself in both cases.
                Text {
                    width: parent.width
                    visible: Meeting.failed
                    text: "Could not read the calendar."
                    color: Theme.attention
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.popoutBodySize
                    wrapMode: Text.WordWrap
                }

                Text {
                    width: parent.width
                    visible: !Meeting.failed && Meeting.loaded
                        && Meeting.all.length === 0
                    text: "Nothing else today."
                    color: Theme.overlay0
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.popoutBodySize
                }

                Text {
                    width: parent.width
                    visible: !Meeting.failed && !Meeting.loaded
                    text: "Checking…"
                    color: Theme.overlay0
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.popoutBodySize
                }

                Repeater {
                    model: Meeting.all

                    MeetingRow {
                        required property var modelData
                        meeting: modelData
                        width: body.width
                    }
                }
            }
        }
    }

    component MeetingRow: Rectangle {
        id: row

        required property var meeting

        readonly property bool isNow: !!row.meeting && row.meeting.state === "now"
        readonly property bool hasLink: !!row.meeting && !!row.meeting.url

        height: 40
        radius: Theme.popoutCardRadius
        color: rowHover.hovered ? Theme.surface0 : "transparent"

        Behavior on color {
            ColorAnimation { duration: Theme.animDuration }
        }

        HoverHandler { id: rowHover }

        MouseArea {
            anchors.fill: parent
            cursorShape: row.hasLink ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (row.hasLink) Meeting.openUrl(row.meeting.url)
        }

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: Theme.toastAccent
            visible: row.isNow
            color: Theme.warning
            topLeftRadius: Theme.popoutCardRadius
            bottomLeftRadius: Theme.popoutCardRadius
        }

        Text {
            id: startTime

            anchors.left: parent.left
            anchors.leftMargin: Theme.toastAccent + 8
            anchors.verticalCenter: parent.verticalCenter
            text: root.timeOf(row.meeting ? row.meeting.start : "")
            color: row.isNow ? Theme.warning : Theme.subtext1
            font.family: Theme.fontFamily
            font.pixelSize: Theme.popoutBodySize
        }

        Column {
            anchors.left: startTime.right
            anchors.leftMargin: 12
            anchors.right: linkGlyph.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
                width: parent.width
                text: row.meeting ? row.meeting.title : ""
                color: Theme.text
                elide: Text.ElideRight
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize
            }

            Text {
                width: parent.width
                text: row.meeting
                    ? (row.isNow
                        ? row.meeting.minutes + "m left"
                        : "in " + row.meeting.minutes + "m")
                    : ""
                color: Theme.overlay0
                elide: Text.ElideRight
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize - 3
            }
        }

        Text {
            id: linkGlyph

            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            visible: row.hasLink
            text: Theme.glyph("earth")
            color: rowHover.hovered ? Theme.text : Theme.overlay0
            font.family: Theme.fontFamily
            font.pixelSize: Theme.popoutBodySize - 1

            Behavior on color {
                ColorAnimation { duration: Theme.animDuration }
            }
        }
    }
}
