// ---------------- clock popout: a month grid ----------------

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import qs.theme
import qs.components
import qs.services

Popout {
    id: root

    // Months offset from the current one. 0 is this month.
    property int monthOffset: 0

    onShownChanged: if (!shown) monthOffset = 0

    // Not `shown`: that is Popout's own property, and the collision fails
    // the whole config with "Property value set multiple times".
    readonly property var shownMonth: {
        const d = new Date(clock.date);
        d.setDate(1);                    // avoid day-31 rollover
        d.setMonth(d.getMonth() + monthOffset);
        return d;
    }

    // Always six, so the height does not change between months.
    readonly property int weeks: 6

    readonly property var cells: {
        const first = new Date(shownMonth);
        // Monday-first: JS getDay() is 0=Sunday, so shift it.
        const lead = (first.getDay() + 6) % 7;

        const start = new Date(first);
        start.setDate(1 - lead);

        const today = new Date(clock.date);
        const out = [];
        for (let i = 0; i < weeks * 7; i++) {
            const d = new Date(start);
            d.setDate(start.getDate() + i);
            out.push({
                day: d.getDate(),
                outside: d.getMonth() !== shownMonth.getMonth(),
                today: d.getDate() === today.getDate()
                       && d.getMonth() === today.getMonth()
                       && d.getFullYear() === today.getFullYear()
            });
        }
        return out;
    }

    contentWidth: Theme.calCellSize * 7 + Theme.popoutPadding * 2
    contentHeight: Theme.popoutPadding * 2
                 + 30
                 + Theme.popoutGap
                 + 20
                 + Theme.calCellSize * weeks

    Column {
        anchors.fill: parent
        anchors.margins: Theme.popoutPadding
        spacing: Theme.popoutGap

        // ---- month, with the way back and forward ----
        Item {
            width: parent.width
            height: 30

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: Theme.glyph("chevronLeft")
                color: prevHover.hovered ? Theme.text : Theme.overlay0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize + 3

                HoverHandler { id: prevHover }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.monthOffset--
                }
            }

            // Click returns to this month.
            Text {
                anchors.centerIn: parent
                text: Qt.formatDateTime(root.shownMonth, "MMMM yyyy")
                color: root.monthOffset === 0
                    ? Theme.text
                    : (monthHover.hovered ? Theme.mauve : Theme.subtext1)
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize + 1

                HoverHandler { id: monthHover }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    cursorShape: root.monthOffset === 0
                        ? Qt.ArrowCursor : Qt.PointingHandCursor
                    onClicked: root.monthOffset = 0
                }
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: Theme.glyph("chevronRight")
                color: nextHover.hovered ? Theme.text : Theme.overlay0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize + 3

                HoverHandler { id: nextHover }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -8
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.monthOffset++
                }
            }
        }

        // ---- weekday headings, Monday first ----
        Row {
            width: parent.width
            height: 20

            Repeater {
                model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

                Text {
                    required property string modelData

                    width: Theme.calCellSize
                    height: 20
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: modelData
                    color: Theme.overlay0
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.popoutBodySize - 2
                }
            }
        }

        // ---- the grid ----
        Grid {
            columns: 7
            rows: root.weeks

            Repeater {
                model: root.cells

                Item {
                    required property var modelData

                    width: Theme.calCellSize
                    height: Theme.calCellSize

                    Rectangle {
                        anchors.centerIn: parent
                        width: Theme.calMarkerSize
                        height: Theme.calMarkerSize
                        radius: width / 2
                        color: Theme.mauve
                        visible: modelData.today
                    }

                    Text {
                        anchors.centerIn: parent
                        text: modelData.day
                        color: modelData.today ? Theme.crust
                             : modelData.outside ? Theme.surface2
                             : Theme.subtext1
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.popoutBodySize
                    }
                }
            }
        }
    }
}
