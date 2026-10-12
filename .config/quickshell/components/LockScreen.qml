// The session lock surface (ext-session-lock: the compositor holds the lock
// if this process dies). Authentication lives in services/Lock.qml.
// Locked out by a bug? `qs ipc call lock unlock`, or from another TTY:
//   hyprctl --instance 0 eval 'hl.clear_crashed_lockscreen()'

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.theme
import qs.services

WlSessionLock {
    id: root

    locked: Lock.locked

    // Lets the service know the lock is genuinely up, not merely requested.
    onSecureChanged: Lock.secure = root.secure

    surface: WlSessionLockSurface {
        id: surface

        // Never transparent: that can leak the desktop.
        color: Theme.crust

        Image {
            anchors.fill: parent
            source: Wallpaper.path ? "file://" + Wallpaper.path : ""
            fillMode: Wallpaper.fillMode
            asynchronous: true
            sourceSize.width: surface.width
            sourceSize.height: surface.height
        }

        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: 0.55
        }

        Column {
            anchors.centerIn: parent
            spacing: 26

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(lockClock.date, "HH:mm")
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 96
                font.weight: Font.Light
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDate(lockClock.date, "dddd, d MMMM")
                color: Theme.subtext0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize + 2
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter

                width: 320
                height: 44
                radius: 22
                color: Theme.popoutCard
                border.width: 1
                border.color: Lock.messageIsError
                    ? Theme.attention
                    : (field.activeFocus ? Theme.mauve : Theme.popoutEdge)

                Behavior on border.color {
                    ColorAnimation { duration: Theme.animDuration }
                }

                TextInput {
                    id: field

                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18

                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.popoutBodySize + 1

                    echoMode: TextInput.Password
                    passwordCharacter: "•"

                    // Disabled while PAM runs, so a second Enter cannot overlap.
                    enabled: !Lock.busy

                    onAccepted: Lock.authenticate(field.text)

                    // The surface has exclusive keyboard focus, but something must hold it.
                    Component.onCompleted: field.forceActiveFocus()

                    Connections {
                        target: surface
                        function onVisibleChanged() {
                            if (surface.visible) field.forceActiveFocus();
                        }
                    }

                    Connections {
                        target: Lock
                        function onFailed() {
                            field.text = "";
                            field.forceActiveFocus();
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: field.text === "" && !Lock.busy
                    text: "Password"
                    color: Theme.overlay0
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.popoutBodySize + 1
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Lock.busy ? "Checking…" : (Lock.message || " ")
                color: Lock.messageIsError ? Theme.attention : Theme.subtext0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize - 1
            }
        }

        SystemClock {
            id: lockClock
            precision: SystemClock.Seconds
        }
    }
}
