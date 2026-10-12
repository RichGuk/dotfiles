// One place in the weather location picker: a search result or a saved entry.

import QtQuick
import qs.theme

Item {
    id: root

    // { name, region, lat, lon }
    required property var place

    property bool current: false

    // Its click is separate from the row's, so removing a place does not select it.
    property string trailing: ""

    signal activated()
    signal trailingClicked()

    height: Theme.popoutRowHeight

    Rectangle {
        anchors.fill: parent
        radius: Theme.popoutCardRadius
        color: rowHover.hovered ? Theme.popoutCard : "transparent"

        Behavior on color {
            ColorAnimation { duration: Theme.animDuration }
        }
    }

    HoverHandler { id: rowHover }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }

    Rectangle {
        id: currentDot

        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        width: 6
        height: 6
        radius: 3
        color: Theme.mauve
        visible: root.current
    }

    Text {
        id: placeName

        anchors.left: parent.left
        anchors.leftMargin: 22
        anchors.verticalCenter: parent.verticalCenter
        text: root.place.name
        color: root.current ? Theme.text : Theme.subtext1
        font.family: Theme.fontFamily
        font.pixelSize: Theme.popoutBodySize
    }

    Text {
        anchors {
            left: placeName.right
            leftMargin: 8
            right: trailingGlyph.left
            rightMargin: 8
            verticalCenter: parent.verticalCenter
        }
        text: root.place.region || ""
        color: Theme.overlay0
        elide: Text.ElideRight
        font.family: Theme.fontFamily
        font.pixelSize: Theme.popoutBodySize - 1
    }

    Text {
        id: trailingGlyph

        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        text: root.trailing
        visible: !!root.trailing && (rowHover.hovered || trailHover.hovered)
        color: trailHover.hovered ? Theme.text : Theme.overlay0
        font.family: Theme.fontFamily
        font.pixelSize: Theme.popoutBodySize

        HoverHandler { id: trailHover }

        MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            cursorShape: Qt.PointingHandCursor
            onClicked: root.trailingClicked()
        }
    }
}
