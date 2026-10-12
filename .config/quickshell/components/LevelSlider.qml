// A draggable level, 0..1.

import QtQuick
import qs.theme

Item {
    id: root

    // Never mutated locally: the service is the source of truth.
    property real value: 0

    signal moved(real value)

    implicitHeight: Theme.sliderHitHeight

    Rectangle {
        id: track

        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: Theme.sliderTrackHeight
        radius: height / 2
        color: Theme.surface0

        Rectangle {
            id: fill

            width: Math.max(0, Math.min(1, root.value)) * parent.width
            height: parent.height
            radius: parent.radius
            color: Theme.mauve

            // No animation while dragging, or the fill lags the pointer.
            Behavior on width {
                enabled: !hit.pressed
                NumberAnimation {
                    duration: Theme.animDuration
                    easing.type: Theme.animEasing
                }
            }
        }
    }

    Rectangle {
        id: knob

        x: Math.max(0, Math.min(1, root.value)) * track.width - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: hit.pressed || hoverArea.hovered
            ? Theme.sliderKnobSize : 0
        height: width
        radius: width / 2
        color: Theme.text

        Behavior on width {
            NumberAnimation {
                duration: Theme.animDuration
                easing.type: Theme.animEasing
            }
        }
    }

    HoverHandler { id: hoverArea }

    MouseArea {
        id: hit

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        onPressed: mouse => root.emitFor(mouse.x)
        onPositionChanged: mouse => { if (pressed) root.emitFor(mouse.x); }
    }

    function emitFor(x) {
        root.moved(Math.max(0, Math.min(1, x / root.width)));
    }
}
