// ---------------- network popout ----------------
// Height is measured, not summed: Column's implicitHeight skips the
// sections that come and go.

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import qs.theme
import qs.components
import qs.services

Popout {
    id: root

    contentWidth: 360
    contentHeight: netCol.implicitHeight + Theme.popoutPadding * 2

    // SSID awaiting a passphrase. Also drives needsKeyboard, without which
    // the TextInput can never take focus.
    property string passwordFor: ""

    needsKeyboard: passwordFor !== ""

    // The service only pings and rescans while this is open.
    onShownChanged: {
        Network.detailsVisible = shown;
        if (!shown) {
            root.passwordFor = "";
            pwField.text = "";
        }
    }

    Column {
        id: netCol

        anchors.fill: parent
        anchors.margins: Theme.popoutPadding
        spacing: Theme.popoutGap

        // ---- what we are on ----
        Item {
            width: parent.width
            height: 40

            Text {
                id: netIcon

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 26
                text: Theme.glyph(Network.glyphName)
                color: Network.online ? Theme.text : Theme.overlay0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize + 6
            }

            Text {
                anchors.left: netIcon.right
                anchors.leftMargin: Theme.popoutGap - 4
                anchors.top: parent.top
                text: Network.label
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize + 2
            }

            Text {
                anchors.left: netIcon.right
                anchors.leftMargin: Theme.popoutGap - 4
                anchors.bottom: parent.bottom
                text: {
                    const bits = [];
                    if (Network.activeWifi)
                        bits.push(Network.activeWifi.signal + "%");
                    if (Network.wiredUp) bits.push("ethernet");
                    if (Network.anyTunnelUp) bits.push("tunnelled");
                    if (!bits.length) bits.push("not connected");
                    return bits.join("  ·  ");
                }
                color: Theme.overlay0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize - 1
            }

            // Wifi radio toggle.
            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: Network.wifiPresent
                width: 46
                height: 26
                radius: 13
                color: Network.wifiEnabled
                    ? Theme.mauve : Theme.surface0

                Behavior on color {
                    ColorAnimation { duration: Theme.animDuration }
                }

                Rectangle {
                    x: Network.wifiEnabled ? parent.width - width - 3 : 3
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20
                    height: 20
                    radius: 10
                    color: Network.wifiEnabled
                        ? Theme.crust : Theme.overlay0

                    Behavior on x {
                        NumberAnimation {
                            duration: Theme.animDuration
                            easing.type: Theme.animEasing
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Network.setWifiEnabled(!Network.wifiEnabled)
                }
            }
        }

        // ---- networks to join ----
        Column {
            width: parent.width
            spacing: 0
            visible: Network.wifiPresent && Network.wifiEnabled

            Item {
                width: parent.width
                height: 22

                Text {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    text: "NETWORKS"
                    color: Theme.overlay0
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.popoutBodySize - 2
                    font.letterSpacing: 0.5
                }

                Text {
                    id: rescanBtn

                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.topMargin: -2
                    text: Theme.glyph("refresh")
                    color: rescanHover.hovered
                        ? Theme.text : Theme.overlay0
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.popoutBodySize

                    RotationAnimation on rotation {
                        running: Network.wifiNetworks.length === 0
                        from: 0; to: 360
                        duration: 900
                        loops: Animation.Infinite
                    }

                    HoverHandler { id: rescanHover }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -8
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Network.rescan()
                    }
                }
            }

            Text {
                width: parent.width
                visible: Network.wifiNetworks.length === 0
                text: "Scanning…"
                color: Theme.overlay0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize
                bottomPadding: 4
            }

            Repeater {
                model: Network.wifiNetworks

                Item {
                    required property var modelData

                    width: parent.width
                    height: Theme.popoutRowHeight

                    readonly property bool busy:
                        Network.connecting === modelData.ssid

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.popoutCardRadius
                        color: netRowHover.hovered
                            ? Theme.popoutCard : "transparent"

                        Behavior on color {
                            ColorAnimation { duration: Theme.animDuration }
                        }
                    }

                    HoverHandler { id: netRowHover }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData.active) {
                                Network.disconnectWifi();
                                return;
                            }
                            if (modelData.known || modelData.open) {
                                Network.connectWifi(modelData.ssid, "");
                                return;
                            }
                            root.passwordFor = modelData.ssid;
                            pwField.text = "";
                            pwField.forceActiveFocus();
                        }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 6
                        height: 6
                        radius: 3
                        color: Theme.mauve
                        visible: modelData.active
                    }

                    Text {
                        anchors {
                            left: parent.left
                            leftMargin: 22
                            right: netRowIcons.left
                            rightMargin: 8
                            verticalCenter: parent.verticalCenter
                        }
                        text: modelData.ssid
                        elide: Text.ElideRight
                        color: modelData.active
                            ? Theme.text : Theme.subtext1
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.popoutBodySize
                    }

                    // Fixed 20x20 centred boxes: Row top-aligns, and the glyphs
                    // do not share a bounding box, so the icons would sit unevenly.
                    Row {
                        id: netRowIcons

                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        // Saved network; becomes the forget button on hover.
                        Text {
                            width: 20
                            height: 20
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter

                            text: Theme.glyph(netRowHover.hovered
                                ? "closeCircle" : "checkCircle")
                            visible: modelData.known
                            color: netRowHover.hovered
                                ? Theme.attention : Theme.overlay0
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.popoutBodySize - 2

                            // z is required: without it the click falls through
                            // to the row and disconnects instead of forgetting.
                            MouseArea {
                                anchors.fill: parent
                                z: 10
                                enabled: netRowHover.hovered
                                cursorShape: Qt.PointingHandCursor
                                onClicked: mouse => {
                                    mouse.accepted = true;
                                    Network.forget(modelData.ssid);
                                }
                            }
                        }

                        Text {
                            width: 20
                            height: 20
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter

                            text: Theme.glyph("lock")
                            visible: !modelData.open
                            color: Theme.overlay0
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.popoutBodySize - 2
                        }

                        Text {
                            width: 20
                            height: 20
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter

                            text: Theme.glyph(
                                Network.signalGlyph(modelData.signal))
                            color: modelData.active
                                ? Theme.mauve : Theme.subtext1
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.popoutBodySize
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.popoutCardRadius
                        color: Theme.crust
                        opacity: parent.busy ? 0.75 : 0
                        visible: opacity > 0

                        Behavior on opacity {
                            NumberAnimation { duration: Theme.animDuration }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "Connecting…"
                            color: Theme.subtext1
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.popoutBodySize - 1
                        }
                    }
                }
            }

            // ---- passphrase, inline ----
            Item {
                width: parent.width
                height: root.passwordFor !== "" ? 40 : 0
                visible: height > 0
                clip: true

                Behavior on height {
                    NumberAnimation {
                        duration: Theme.animDuration
                        easing.type: Theme.animEasing
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 4
                    height: 30
                    radius: Theme.popoutCardRadius
                    color: Theme.popoutCard

                    Text {
                        id: pwIcon

                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: Theme.glyph("lock")
                        color: Theme.overlay0
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.popoutBodySize - 2
                    }

                    TextInput {
                        id: pwField

                        anchors {
                            left: pwIcon.right
                            leftMargin: 8
                            right: pwGo.left
                            rightMargin: 8
                            verticalCenter: parent.verticalCenter
                        }

                        echoMode: TextInput.Password
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.popoutBodySize
                        selectByMouse: true
                        selectionColor: Theme.mauve

                        onAccepted: {
                            Network.connectWifi(
                                root.passwordFor, text);
                            root.passwordFor = "";
                            text = "";
                        }

                        Keys.onEscapePressed: {
                            root.passwordFor = "";
                            pwField.text = "";
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: pwField.text.length === 0
                            text: "Password for "
                                + root.passwordFor
                            color: Theme.overlay0
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.popoutBodySize
                        }
                    }

                    Text {
                        id: pwGo

                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: Theme.glyph("chevronRight")
                        color: pwField.text.length > 0
                            ? Theme.mauve : Theme.overlay0
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.popoutBodySize

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!pwField.text.length) return;
                                Network.connectWifi(
                                    root.passwordFor,
                                    pwField.text);
                                root.passwordFor = "";
                                pwField.text = "";
                            }
                        }
                    }
                }
            }

            Text {
                width: parent.width
                visible: Network.lastError !== ""
                text: Theme.glyph("alert") + "  " + Network.lastError
                color: Theme.attention
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize - 1
                topPadding: 4
            }
        }

        // ---- addresses ----
        Column {
            width: parent.width
            spacing: 0

            Text {
                text: "ADDRESSES"
                color: Theme.overlay0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize - 2
                font.letterSpacing: 0.5
                bottomPadding: 6
            }

            // From `ip`, not NM, so unmanaged interfaces show too.
            Repeater {
                model: Network.addressRows

                Item {
                    required property var modelData

                    width: parent.width
                    height: 26

                    readonly property bool justCopied:
                        Network.copied === modelData.address

                    // Click copies the address.
                    Rectangle {
                        anchors.fill: parent
                        anchors.leftMargin: -6
                        anchors.rightMargin: -6
                        radius: Theme.popoutCardRadius
                        color: addrHover.hovered
                            ? Theme.popoutCard : "transparent"

                        Behavior on color {
                            ColorAnimation { duration: Theme.animDuration }
                        }
                    }

                    HoverHandler { id: addrHover }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Network.copy(modelData.address)
                    }

                    Text {
                        id: ifIcon

                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 22
                        text: Theme.glyph(modelData.wireless
                            ? "wifi4"
                            : modelData.tunnel ? "shieldLock" : "lan")
                        color: Theme.overlay0
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.popoutBodySize - 1
                    }

                    Text {
                        anchors.left: ifIcon.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 96
                        text: modelData.iface
                        elide: Text.ElideRight
                        color: Theme.subtext1
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.popoutBodySize - 1
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: parent.justCopied
                            ? "Copied" : modelData.address
                        color: parent.justCopied
                            ? Theme.mauve : Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.popoutBodySize - 1
                    }
                }
            }

            // Public address.
            Item {
                width: parent.width
                height: 26

                readonly property bool justCopied:
                    Network.publicIp !== ""
                    && Network.copied === Network.publicIp

                Rectangle {
                    anchors.fill: parent
                    anchors.leftMargin: -6
                    anchors.rightMargin: -6
                    radius: Theme.popoutCardRadius
                    color: pubHover.hovered
                        ? Theme.popoutCard : "transparent"

                    Behavior on color {
                        ColorAnimation { duration: Theme.animDuration }
                    }
                }

                HoverHandler { id: pubHover }

                MouseArea {
                    anchors.fill: parent
                    enabled: Network.publicIp !== ""
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Network.copy(Network.publicIp)
                }

                Text {
                    id: pubIcon

                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 22
                    text: Theme.glyph("earth")
                    color: Theme.overlay0
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.popoutBodySize - 1
                }

                Text {
                    anchors.left: pubIcon.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "public"
                    color: Theme.subtext1
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.popoutBodySize - 1
                }

                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: parent.justCopied
                        ? "Copied" : (Network.publicIp || "—")
                    color: parent.justCopied
                        ? Theme.mauve : Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.popoutBodySize - 1
                }
            }
        }

        // ---- link quality ----
        Item {
            width: parent.width
            height: 24

            Text {
                id: rttIcon

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 22
                text: Theme.glyph("speedometer")
                color: Theme.overlay0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize - 1
            }

            Text {
                anchors.left: rttIcon.right
                anchors.verticalCenter: parent.verticalCenter
                text: Network.latencyMs >= 0
                    ? Network.latencyMs.toFixed(1) + " ms"
                    : "measuring…"
                color: Theme.subtext1
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize - 1
            }

            Text {
                id: lossIcon

                anchors.right: lossText.left
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                text: Theme.glyph("transfer")
                color: Theme.overlay0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize - 1
            }

            Text {
                id: lossText

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: Network.packetLoss >= 0
                    ? Network.packetLoss + "% loss" : "—"
                color: Network.packetLoss > 0
                    ? Theme.attention : Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize - 1
            }
        }

        // ---- wireguard ----
        // NM connections, so no root needed (unlike wg-quick).
        Column {
            width: parent.width
            spacing: 0
            visible: Network.tunnels.length > 0

            Text {
                text: "WIREGUARD"
                color: Theme.overlay0
                font.family: Theme.fontFamily
                font.pixelSize: Theme.popoutBodySize - 2
                font.letterSpacing: 0.5
                bottomPadding: 4
            }

            Repeater {
                model: Network.tunnels

                Item {
                    required property var modelData

                    width: parent.width
                    height: Theme.popoutRowHeight

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.popoutCardRadius
                        color: wgHover.hovered
                            ? Theme.popoutCard : "transparent"

                        Behavior on color {
                            ColorAnimation { duration: Theme.animDuration }
                        }
                    }

                    HoverHandler { id: wgHover }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Network.setTunnel(
                            modelData.name, !modelData.active)
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 6
                        height: 6
                        radius: 3
                        color: Theme.mauve
                        visible: modelData.active
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 22
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.name
                        color: modelData.active
                            ? Theme.text : Theme.subtext1
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.popoutBodySize
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.active ? "on" : "off"
                        color: modelData.active
                            ? Theme.mauve : Theme.overlay0
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.popoutBodySize - 1
                    }
                }
            }
        }
    }
}
