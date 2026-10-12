// The desktop background: one layer-shell surface per output, below everything.
// exclusiveZone 0 so it fills behind the bar too.

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

PanelWindow {
    id: root

    required property var modelData

    screen: modelData

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    exclusiveZone: 0

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "quickshell-wallpaper"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Empty input region: a background that takes clicks swallows the desktop's.
    mask: Region {}

    color: "#11111b"

    Image {
        id: wallpaper

        anchors.fill: parent

        source: Wallpaper.path ? "file://" + Wallpaper.path : ""
        fillMode: Wallpaper.fillMode

        asynchronous: true
        cache: true

        // Decode at display size, not full resolution per output.
        sourceSize.width: root.screen ? root.screen.width : 0
        sourceSize.height: root.screen ? root.screen.height : 0

        opacity: status === Image.Ready ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }
    }
}
