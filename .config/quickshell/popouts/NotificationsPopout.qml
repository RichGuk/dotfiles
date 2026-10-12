// ---------------- notification centre ----------------
// A toast timing out does not close its notification, so its actions still work here.

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import qs.theme
import qs.components
import qs.services

Popout {
    id: root

    contentWidth: 380

    // The list scrolls beyond this rather than growing the panel.
    readonly property int maxListHeight: 420

    contentHeight: Theme.popoutPadding * 2
                 + header.height
                 + Theme.popoutGap
                 + Math.max(28, Math.min(root.maxListHeight, list.contentHeight))

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
                text: "NOTIFICATIONS"
                color: Theme.overlay0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize - 2
                font.letterSpacing: 0.5
            }

            Text {
                anchors.left: title.right
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                visible: Notifications.count > 0
                text: Notifications.count
                color: Notifications.hasCritical ? Theme.attention : Theme.mauve
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize - 2
            }

            // Fixed boxes with exact hit areas, not negative-margin MouseAreas:
            // those overlapped, and the broom (clear all) stole the bell's clicks.
            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                // Do not disturb: suppresses toasts only; the list still fills.
                Item {
                    width: 24
                    height: 24

                    Text {
                        anchors.centerIn: parent
                        text: Theme.glyph(Notifications.doNotDisturb
                            ? "bellOff" : "bell")
                        color: Notifications.doNotDisturb
                            ? Theme.warning
                            : (dndHover.hovered ? Theme.text : Theme.overlay0)
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.popoutBodySize

                        Behavior on color {
                            ColorAnimation { duration: Theme.animDuration }
                        }
                    }

                    HoverHandler { id: dndHover }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifications.doNotDisturb =
                            !Notifications.doNotDisturb
                    }
                }

                // Clear all.
                Item {
                    width: 24
                    height: 24
                    visible: Notifications.count > 0

                    Text {
                        anchors.centerIn: parent
                        text: Theme.glyph("broom")
                        color: clearHover.hovered
                            ? Theme.attention : Theme.overlay0
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.popoutBodySize

                        Behavior on color {
                            ColorAnimation { duration: Theme.animDuration }
                        }
                    }

                    HoverHandler { id: clearHover }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifications.dismissAll()
                    }
                }
            }
        }

        // ---- the list ----
        Item {
            width: parent.width
            height: Math.max(28, Math.min(root.maxListHeight, list.contentHeight))

            Text {
                anchors.left: parent.left
                anchors.top: parent.top
                visible: Notifications.count === 0
                text: Notifications.doNotDisturb
                    ? "Nothing here. Do not disturb is on."
                    : "Nothing here."
                color: Theme.overlay0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize
            }

            ListView {
                id: list

                anchors.fill: parent
                clip: true
                spacing: 8

                boundsBehavior: Flickable.StopAtBounds

                model: Notifications.all

                delegate: NotificationCard {
                    required property var modelData

                    notif: modelData
                    width: list.width
                }
            }
        }
    }

    // ---- one notification ----
    component NotificationCard: Rectangle {
        id: card

        required property var notif

        implicitHeight: cardBody.implicitHeight + 20
        height: implicitHeight

        radius: Theme.popoutCardRadius
        color: cardHover.hovered ? Theme.surface0 : Theme.popoutCard

        Behavior on color {
            ColorAnimation { duration: Theme.animDuration }
        }

        HoverHandler { id: cardHover }

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: Theme.toastAccent
            color: Notifications.urgencyColour(card.notif)
            topLeftRadius: Theme.popoutCardRadius
            bottomLeftRadius: Theme.popoutCardRadius
        }

        // Body click runs the default action. Declared first so the dismiss
        // and action buttons stay above it.
        MouseArea {
            anchors.fill: parent
            cursorShape: card.defaultAction
                ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: card.activate(card.defaultAction)
        }

        readonly property var defaultAction: {
            if (!card.notif) return null;
            for (const a of card.notif.actions) {
                if (a.identifier === "default") return a;
            }
            return null;
        }

        readonly property var buttonActions: {
            const out = [];
            if (!card.notif) return out;
            for (const a of card.notif.actions) {
                if (a.identifier !== "default") out.push(a);
            }
            return out;
        }

        function activate(action) {
            if (!action || !card.notif) return;
            action.invoke();
            if (!card.notif.resident) Notifications.dismiss(card.notif);
        }

        Column {
            id: cardBody

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: Theme.toastAccent + 10
            anchors.rightMargin: 10
            anchors.topMargin: 10
            spacing: 2

            Item {
                width: parent.width
                height: 15

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: Notifications.appLabel(card.notif)
                    color: Notifications.urgencyColour(card.notif)
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.popoutBodySize - 3
                    font.letterSpacing: 0.4
                }

                Text {
                    anchors.right: rowClose.left
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    text: Notifications.ago(Notifications.arrivalOf(card.notif))
                    color: Theme.overlay0
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.popoutBodySize - 3
                }

                Text {
                    id: rowClose

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: cardHover.hovered ? 1 : 0
                    text: Theme.glyph("close")
                    color: rowCloseHover.hovered ? Theme.attention : Theme.overlay0
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.popoutBodySize - 3

                    Behavior on opacity {
                        NumberAnimation { duration: Theme.animDuration }
                    }

                    HoverHandler { id: rowCloseHover }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifications.dismiss(card.notif)
                    }
                }
            }

            Text {
                width: parent.width
                text: card.notif ? card.notif.summary : ""
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.WordWrap
            }

            Text {
                width: parent.width
                visible: !!card.notif && card.notif.body !== ""
                text: card.notif ? card.notif.body : ""
                // The server advertises body markup, so senders may use it.
                textFormat: Text.StyledText
                color: Theme.subtext1
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize - 1
                elide: Text.ElideRight
                maximumLineCount: 3
                wrapMode: Text.WordWrap
            }

            // Actions.
            Row {
                width: parent.width
                spacing: 6
                topPadding: 4
                visible: card.buttonActions.length > 0

                Repeater {
                    model: card.buttonActions

                    Rectangle {
                        required property var modelData

                        width: rowActionLabel.implicitWidth + 16
                        height: 22
                        radius: Theme.popoutCardRadius
                        color: rowActionHover.hovered
                            ? Theme.surface2 : Theme.surface1

                        Behavior on color {
                            ColorAnimation { duration: Theme.animDuration }
                        }

                        Text {
                            id: rowActionLabel

                            anchors.centerIn: parent
                            text: modelData.text
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.popoutBodySize - 2
                        }

                        HoverHandler { id: rowActionHover }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: card.activate(modelData)
                        }
                    }
                }
            }

            Item {
                width: 1
                height: 6
            }
        }
    }
}
