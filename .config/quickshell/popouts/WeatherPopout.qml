// ---------------- weather popout ----------------

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import qs.theme
import qs.components
import qs.services

Popout {
    id: root

    // Without this the search field cannot take focus. Only while the
    // picker is open, so opening the weather does not steal focus.
    needsKeyboard: pickerOpen

    // The picker replaces the forecast.
    property bool pickerOpen: false

    // `shown`, not `visible`: visible lags for the fade-out.
    onShownChanged: if (!shown) pickerOpen = false

    contentWidth: 330
    // Summed from item heights; keep in step with the sections below.
    contentHeight: Theme.popoutPadding * 2
                 + wxLocation.height + Theme.popoutGap
                 + (Weather.awayFromPinned
                     ? Theme.popoutRowHeight + Theme.popoutGap : 0)
                 + wxHeader.height + Theme.popoutGap
                 + (pickerOpen
                     ? wxPicker.height
                     : Weather.forecast.length * Theme.popoutRowHeight)

    Column {
        anchors.fill: parent
        anchors.margins: Theme.popoutPadding
        spacing: Theme.popoutGap

        // ---- where this is for ----
        Item {
            id: wxLocation

            width: parent.width
            height: Theme.popoutBodySize + 4

            Text {
                id: wxPlaceName

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: Weather.placeName
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize
            }

            Text {
                id: wxRegion

                anchors.left: wxPlaceName.right
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: Weather.placeRegion
                color: Theme.overlay0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize
            }

            // Right-hand side: data trust, then the picker toggle.
            Text {
                id: wxTrust

                anchors.right: wxPickerToggle.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                visible: !!Weather.current
                         && (Weather.state === Weather.stateError
                             || Weather.stale)
                text: Weather.state === Weather.stateError
                    ? "offline" : "stale"
                color: Theme.attention
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize - 1
            }

            Text {
                id: wxPickerToggle

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: Theme.glyph(root.pickerOpen
                    ? "chevronUp" : "chevronDown")
                color: pickerHover.hovered
                    ? Theme.text : Theme.overlay0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize + 2

                HoverHandler { id: pickerHover }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.pickerOpen =
                        !root.pickerOpen
                }
            }
        }

        // ---- "you seem to be elsewhere" ----
        // Offers the switch rather than taking it.
        Rectangle {
            width: parent.width
            height: visible ? Theme.popoutRowHeight : 0
            visible: Weather.awayFromPinned
            radius: Theme.popoutCardRadius
            color: Theme.popoutCard

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: "You seem to be in "
                    + (Weather.detected ? Weather.detected.name : "")
                color: Theme.subtext1
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: "use it"
                color: followHover.hovered
                    ? Theme.mauve : Theme.subtext0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize

                HoverHandler { id: followHover }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Weather.follow()
                }
            }
        }

        // ---- loading / failed ----
        // Only with no data at all; a failed refresh keeps old readings
        // and flags them in the location line.
        Item {
            width: parent.width
            height: visible ? 40 : 0
            visible: !Weather.current

            Text {
                anchors.centerIn: parent
                text: Weather.state === Weather.stateError
                    ? "Weather unavailable"
                    : "Loading…"
                color: Weather.state === Weather.stateError
                    ? Theme.attention : Theme.overlay0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize
            }
        }

        // ---- today, as the header ----
        Item {
            id: wxHeader

            visible: !!Weather.current

            width: parent.width
            height: visible ? 52 : 0

            Text {
                id: nowIcon

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: Theme.glyph(Weather.currentOr.cond)
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 34
            }

            Text {
                id: nowTemp

                anchors.left: nowIcon.right
                anchors.leftMargin: Theme.popoutGap
                anchors.verticalCenter: parent.verticalCenter
                text: Weather.currentOr.temp + "°"
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 28
            }

            Column {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    anchors.right: parent.right
                    text: Weather.currentOr.summary
                    color: Theme.subtext1
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.popoutBodySize
                }

                Text {
                    anchors.right: parent.right
                    text: Weather.currentOr.high + "° / "
                        + Weather.currentOr.low + "°"
                        + (Weather.currentOr.rain > 0
                            ? "   " + Theme.glyph("wxDroplet")
                              + " " + Weather.currentOr.rain + "%"
                            : "")
                    color: Theme.overlay0
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.popoutBodySize
                }
            }
        }

        // ---- location picker ----
        Column {
            id: wxPicker

            width: parent.width
            spacing: 6
            visible: root.pickerOpen

            // Search field; needs needsKeyboard (above).
            Rectangle {
                width: parent.width
                height: 30
                radius: Theme.popoutCardRadius
                color: Theme.popoutCard

                Text {
                    id: searchIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: Theme.glyph("search")
                    color: Theme.overlay0
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.popoutBodySize
                }

                TextInput {
                    id: searchField

                    anchors {
                        left: searchIcon.right
                        leftMargin: 8
                        right: parent.right
                        rightMargin: 10
                        verticalCenter: parent.verticalCenter
                    }

                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.popoutBodySize
                    selectByMouse: true
                    clip: true

                    // Debounced, to spare the geocoder.
                    onTextChanged: searchDebounce.restart()

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        visible: !searchField.text
                        text: "Search for a place"
                        color: Theme.overlay0
                        font: searchField.font
                    }
                }

                Timer {
                    id: searchDebounce
                    interval: 300
                    onTriggered: Weather.search(searchField.text)
                }
            }

            // Search results, or saved places when there are none.
            Repeater {
                model: Weather.searchResults

                LocationRow {
                    required property var modelData
                    place: modelData
                    width: parent.width
                    trailing: Theme.glyph("pin")
                    onActivated: {
                        Weather.select(modelData);
                        Weather.save(modelData);
                        searchField.text = "";
                        Weather.searchResults = [];
                        root.pickerOpen = false;
                    }
                }
            }

            Text {
                visible: Weather.searchResults.length === 0
                         && Weather.savedLocations.length > 0
                text: "Saved"
                color: Theme.overlay0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize - 1
            }

            Repeater {
                model: Weather.searchResults.length === 0
                    ? Weather.savedLocations : []

                LocationRow {
                    required property var modelData
                    place: modelData
                    width: parent.width
                    current: Weather.sameSpot(modelData, Weather.location)
                    trailing: Theme.glyph("close")
                    onActivated: {
                        Weather.select(modelData);
                        root.pickerOpen = false;
                    }
                    onTrailingClicked: Weather.forget(modelData)
                }
            }

            // Back to following the detected city.
            Text {
                visible: Weather.mode === Weather.modePinned
                         && !!Weather.detected
                // Guarded anyway: an invisible item's bindings still evaluate.
                text: Theme.glyph("pin") + "  Use my location ("
                    + (Weather.detected ? Weather.detected.name : "")
                    + ")"
                color: useLocHover.hovered
                    ? Theme.mauve : Theme.subtext0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize

                HoverHandler { id: useLocHover }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Weather.follow();
                        root.pickerOpen = false;
                    }
                }
            }
        }

        // ---- the coming days ----
        // Own Column with no spacing, or each row gets popoutGap and the
        // list overflows the summed contentHeight.
        Column {
            width: parent.width
            spacing: 0
            visible: !root.pickerOpen
                     && Weather.forecast.length > 0

        Repeater {
            model: Weather.forecast

            Item {
                required property var modelData

                width: parent.width
                height: Theme.popoutRowHeight

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    x: 0
                    width: 20
                    horizontalAlignment: Text.AlignRight
                    text: modelData.date
                    color: Theme.subtext0
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.popoutBodySize
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    x: 32
                    text: modelData.day
                    color: Theme.subtext0
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.popoutBodySize
                }

                Text {
                    id: condIcon

                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: rainChance.left
                    anchors.rightMargin: 8
                    text: Theme.glyph(modelData.cond)
                    color: Theme.subtext0
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.popoutBodySize + 3
                }

                // Fixed width even when empty, so the temperatures line up.
                Item {
                    id: rainChance

                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: highTemp.left
                    anchors.rightMargin: Theme.popoutGap
                    width: 44
                    height: parent.height

                    Row {
                        anchors.centerIn: parent
                        spacing: 2
                        visible: modelData.rain > 0

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Theme.glyph("wxDroplet")
                            color: Theme.overlay0
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.popoutBodySize - 1
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.rain + "%"
                            color: Theme.overlay0
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.popoutBodySize
                        }
                    }
                }

                Text {
                    id: highTemp

                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: lowTemp.left
                    anchors.rightMargin: 8
                    width: 28
                    horizontalAlignment: Text.AlignRight
                    text: modelData.high + "°"
                    color: Theme.subtext1
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.popoutBodySize
                }

                Text {
                    id: lowTemp

                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    width: 28
                    horizontalAlignment: Text.AlignRight
                    text: modelData.low + "°"
                    color: Theme.overlay0
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.popoutBodySize
                }
            }
        }
    }
    }
}
