// A bar module that owns a popout: click target, open indicator, and the
// wiring to the shell's single `openPopout` state.

import QtQuick
import qs.theme

Item {
    id: root

    // Empty means no popout: no indicator, no pointer cursor.
    property string popout: ""

    property string activePopout: ""
    readonly property bool isOpen: popout !== "" && activePopout === popout

    signal activated()

    // Right click, so a module can have a primary action and a popout.
    signal secondaryActivated()

    property bool clickable: popout !== ""

    signal wheeled(var wheel)

    // Width comes from a left-anchored holder, not childrenRect of a centred one:
    // that is a binding loop. opticalTrim nudges one module for glyph side
    // bearing; keep it tiny.
    property int opticalTrim: 0

    implicitWidth: Math.max(0, holder.width - opticalTrim)
    height: Theme.barHeight

    default property alias content: holder.data

    Item {
        id: holder

        anchors.left: parent.left

        width: childrenRect.width

        // Full bar height, not childrenRect.height: BarText centres on its parent,
        // so measuring the child is a binding loop.
        height: parent.height
    }

    // Open indicator. Kept clear of the bar's bottom edge, or it reads as part of
    // the popout's outline.
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 3

        width: root.isOpen ? Theme.moduleIndicatorWidth : 0
        height: Theme.moduleIndicatorHeight
        radius: height / 2
        color: Theme.mauve

        Behavior on width {
            NumberAnimation {
                duration: Theme.animDuration
                easing.type: Theme.animEasing
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: root.clickable || root.popout !== ""
            ? Qt.PointingHandCursor : Qt.ArrowCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) {
                root.secondaryActivated();
                return;
            }
            if (root.clickable) root.activated();
        }

        onWheel: wheel => root.wheeled(wheel)
    }
}
