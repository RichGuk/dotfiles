// One notification, as a card. Each toast owns its expiry, so hover pauses
// only the one under the pointer.

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Notifications
import qs.theme
import qs.services

Item {
    id: root

    required property var notif

    // Set false by the layer while leaving, so the exit animation can play.
    property bool shown: true

    implicitWidth: Theme.toastWidth
    implicitHeight: card.implicitHeight

    property real anim: shown ? 1 : 0

    Behavior on anim {
        NumberAnimation {
            duration: Theme.toastAnimDuration
            easing.type: Theme.animEasing
        }
    }

    opacity: anim
    transform: Translate { x: (1 - root.anim) * (Theme.toastWidth + 20) }

    // Critical notifications get timeout 0, which means never expire.
    readonly property int timeout: Notifications.timeoutFor(root.notif)

    // The spec's "default" action is a click on the card; keep it out of the
    // button row or half of all toasts grow a button labelled "default".
    readonly property var defaultAction: {
        if (!root.notif) return null;
        for (const a of root.notif.actions) {
            if (a.identifier === "default") return a;
        }
        return null;
    }

    readonly property var buttonActions: {
        const out = [];
        if (!root.notif) return out;
        for (const a of root.notif.actions) {
            if (a.identifier !== "default") out.push(a);
        }
        return out;
    }

    function activate(action) {
        if (!action || !root.notif) return;
        action.invoke();
        // `resident` senders want the notification kept after an action.
        if (!root.notif.resident) Notifications.dismiss(root.notif);
    }

    // One animation drives both expiry and the countdown bar, so pausing on hover
    // cannot desync them.
    property real remaining: 1

    NumberAnimation on remaining {
        id: drain

        running: root.timeout > 0 && root.shown
        paused: hover.hovered

        from: 1
        to: 0
        duration: Math.max(1, root.timeout)

        // Takes the toast off screen; the notification stays in the centre.
        onFinished: Notifications.untoast(root.notif)
    }

    HoverHandler { id: hover }

    Rectangle {
        anchors.left: card.left
        anchors.bottom: card.bottom
        anchors.margins: 1
        height: 2
        visible: root.timeout > 0
        width: (card.width - 2) * root.remaining
        color: Notifications.urgencyColour(root.notif)
        opacity: 0.45

        // The card is opaque and declared later; without z the bar is painted over.
        z: 2
    }

    MultiEffect {
        source: card
        anchors.fill: card
        shadowEnabled: true
        shadowColor: Theme.popoutShadowColor
        shadowOpacity: Theme.popoutShadowOpacity
        shadowBlur: 0.7
        shadowVerticalOffset: 4
        blurMax: 24
    }

    Rectangle {
        id: card

        width: Theme.toastWidth
        implicitHeight: body.implicitHeight + Theme.toastPadding * 2
        height: implicitHeight

        color: Theme.popoutBg
        radius: Theme.toastRadius
        border.width: Theme.popoutBorder
        border.color: Theme.popoutEdge

        // Declared before the content so later siblings keep their own clicks.
        MouseArea {
            anchors.fill: parent
            cursorShape: root.defaultAction
                ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: root.activate(root.defaultAction)
        }

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.margins: 1
            width: Theme.toastAccent
            color: Notifications.urgencyColour(root.notif)
            topLeftRadius: Theme.toastRadius - 1
            bottomLeftRadius: Theme.toastRadius - 1
        }

        Column {
            id: body

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: Theme.toastPadding + Theme.toastAccent
            anchors.rightMargin: Theme.toastPadding
            anchors.topMargin: Theme.toastPadding
            spacing: 4

            // ---- who sent it, and when ----
            Item {
                width: parent.width
                height: 16

                Text {
                    id: appLabel

                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: Notifications.appLabel(root.notif)
                    color: Notifications.urgencyColour(root.notif)
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.popoutBodySize - 2
                    font.letterSpacing: 0.4
                }

                Text {
                    anchors.right: closeBtn.left
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    text: Notifications.ago(Notifications.arrivalOf(root.notif))
                    color: Theme.overlay0
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.popoutBodySize - 2
                }

                // Really closes it, unlike expiry.
                Text {
                    id: closeBtn

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: Theme.glyph("close")
                    color: closeHover.hovered ? Theme.attention : Theme.overlay0
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.popoutBodySize - 2

                    Behavior on color {
                        ColorAnimation { duration: Theme.animDuration }
                    }

                    HoverHandler { id: closeHover }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifications.dismiss(root.notif)
                    }
                }
            }

            // ---- the notification itself ----
            Row {
                width: parent.width
                spacing: Theme.toastPadding - 4

                Rectangle {
                    width: visible ? Theme.toastImageSize : 0
                    height: Theme.toastImageSize
                    visible: !!root.notif && root.notif.image !== ""
                    radius: Theme.popoutCardRadius
                    color: Theme.popoutCard
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: root.notif ? root.notif.image : ""
                        sourceSize.width: Theme.toastImageSize * 2
                        sourceSize.height: Theme.toastImageSize * 2
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }

                Column {
                    width: parent.width
                        - (root.notif && root.notif.image !== ""
                            ? Theme.toastImageSize + Theme.toastPadding - 4 : 0)
                    spacing: 2

                    Text {
                        width: parent.width
                        text: root.notif ? root.notif.summary : ""
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.popoutBodySize + 1
                        elide: Text.ElideRight
                        maximumLineCount: 2
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        width: parent.width
                        visible: !!root.notif && root.notif.body !== ""
                        text: root.notif ? root.notif.body : ""

                        // StyledText: we advertise body markup. Not RichText -- far too much HTML
                        // from an arbitrary app's string.
                        textFormat: Text.StyledText

                        color: Theme.subtext1
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.popoutBodySize
                        wrapMode: Text.WordWrap
                        elide: Text.ElideRight
                        maximumLineCount: 4
                    }
                }
            }

            // ---- actions ----
            // Text only: we advertise actionIconsSupported: false.
            Row {
                width: parent.width
                spacing: 6
                topPadding: 4
                visible: root.buttonActions.length > 0

                Repeater {
                    model: root.buttonActions

                    Rectangle {
                        required property var modelData

                        width: actionLabel.implicitWidth + 18
                        height: 24
                        radius: Theme.popoutCardRadius
                        color: actionHover.hovered
                            ? Theme.surface1 : Theme.popoutCard

                        Behavior on color {
                            ColorAnimation { duration: Theme.animDuration }
                        }

                        Text {
                            id: actionLabel

                            anchors.centerIn: parent
                            text: modelData.text
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.popoutBodySize - 1
                        }

                        HoverHandler { id: actionHover }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activate(modelData)
                        }
                    }
                }
            }

            // Bottom padding as a spacer: the top-anchored Column's implicitHeight sizes
            // the card, and a margin would not be counted.
            Item {
                width: 1
                height: Theme.toastPadding - 4
            }
        }
    }
}
