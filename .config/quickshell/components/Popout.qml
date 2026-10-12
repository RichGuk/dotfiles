// Shared popout shell: surface, flared join, border, shadow, placement.
// Size is content-driven: set contentWidth/contentHeight per popout.

import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.theme

// A layer surface, not a PopupWindow: a popup's position is negotiated with
// the compositor and cannot sit flush against a screen edge.
PanelWindow {
    id: root

    required property var barWindow
    required property Item anchorItem

    // The visible panel's size; the window is larger (flare + shadow margins).
    property int contentWidth:  340
    property int contentHeight: 150

    default property alias content: contentHolder.data

    // The window is wider than the panel by a flare and shadow margin per side;
    // a side at the screen edge drops both and sits flush.
    // Edge detection uses the anchor and contentWidth only -- implicitWidth
    // depends on these and would make a binding loop.
    readonly property bool atRightEdge:
        panelCentre + contentWidth / 2 >= barWindow.width - Theme.edgeMargin

    readonly property bool atLeftEdge:
        panelCentre - contentWidth / 2 <= Theme.edgeMargin

    // Summed up the parent chain rather than via mapToItem: a function call
    // registers no binding dependencies, so it would miss a parent Row shifting.
    readonly property real panelCentre: {
        let x = anchorItem.width / 2;
        let item = anchorItem;

        for (let i = 0; i < 16 && item && item !== barWindow.contentItem; i++) {
            x += item.x;
            item = item.parent;
        }
        return x;
    }

    readonly property int leftFlare:  atLeftEdge  ? 0 : Theme.popoutFlare
    readonly property int rightFlare: atRightEdge ? 0 : Theme.popoutFlare

    // The visible outline lands this far inside its box (Shape/MultiEffect
    // rasterisation). Measured, not derived.
    readonly property int popoutOutlineBleed: 4

    // Visible edge = inset + bleed.
    readonly property int edgeInset:
        Theme.popoutEdgeFlush
            ? 0
            : Math.max(0, Theme.popoutEdgeGap - popoutOutlineBleed)

    readonly property int leftInset:
        atLeftEdge ? edgeInset : Theme.popoutShadowMargin
    readonly property int rightInset:
        atRightEdge ? edgeInset : Theme.popoutShadowMargin

    readonly property int leftPad:  leftFlare + leftInset
    readonly property int rightPad: rightFlare + rightInset

    implicitWidth:  contentWidth + leftPad + rightPad
    implicitHeight: contentHeight + Theme.popoutShadowMargin

    color: "transparent"

    screen: barWindow.screen

    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-popout"

    WlrLayershell.keyboardFocus: root.shown && root.needsKeyboard
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None

    // The window is larger than the panel; without a mask the shadow margin
    // swallows clicks beside the popout.
    mask: Region {
        x: root.leftInset
        y: 0
        width: root.implicitWidth - root.leftInset - root.rightInset
        height: root.contentHeight
    }

    // `shown` is the request; `visible` lags on close so the fade can play.
    property bool shown: false

    visible: shown || anim > 0

    property real anim: shown ? 1 : 0

    Behavior on anim {
        NumberAnimation {
            duration: Theme.popoutAnimDuration
            easing.type: Theme.animEasing
        }
    }

    // Dismissal. Not PopupWindow.grabFocus: it grabs for one window and eats the
    // dismissing click, so switching popouts took two clicks.
    signal dismissed()

    // Armed ~80ms after opening, deliberately: Hyprland ignores add_surface for a
    // surface with no role yet, so arming at once whitelisted only the bar and
    // every click on the popout's own content closed it.
    property bool grabArmed: false

    onShownChanged: {
        if (root.shown) grabDelay.restart();
        else root.grabArmed = false;
    }

    Timer {
        id: grabDelay
        interval: 80
        onTriggered: root.grabArmed = true
    }

    // Layer surfaces declare no keyboard interactivity, so a TextInput cannot get
    // focus. OnDemand only while a field needs it -- Exclusive would steal typing.
    property bool needsKeyboard: false

    HyprlandFocusGrab {
        // The bar must be listed too, so a click on another module reaches it.
        windows: [root, root.barWindow]

        active: root.shown && root.grabArmed

        // `shown` check: the compositor also clears the grab as the popout closes.
        onCleared: if (root.shown) root.dismissed();
    }

    // Placement: anchor plus exact margin. Anchoring top lands below the bar's
    // exclusive zone.
    anchors {
        top: true
        left: !root.atRightEdge
        right: root.atRightEdge
    }

    margins.left: root.atRightEdge ? 0 : root.windowX
    margins.right: 0

    readonly property int windowX: {
        if (root.atLeftEdge) return 0;

        const centred =
            Math.round(root.panelCentre - root.contentWidth / 2 - root.leftPad);

        // Clamped: a layer surface has no PopupAdjustment and would hang off-screen.
        const maxX = Math.max(0, root.barWindow.width - root.implicitWidth);
        return Math.max(0, Math.min(centred, maxX));
    }

    // Outline is a path, not a Rectangle: the top corners curve outward into the
    // bar. The stroke follows drawn segments only, so there is no line at the join.
    // Outline and content share this layer so they fade and slide as one.
    Item {
        id: animLayer

        anchors.fill: parent
        opacity: root.anim

        transform: Translate { y: (1 - root.anim) * -6 }

    Shape {
        id: panelShape

        anchors.fill: parent
        anchors.topMargin: 0
        anchors.leftMargin: root.leftInset
        anchors.rightMargin: root.rightInset
        anchors.bottomMargin: Theme.popoutShadowMargin

        // Drawn through the MultiEffect below.
        visible: false

        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            // Referenced by id: PathArc/PathLine are not Items, so `parent` is undefined.
            id: outline

            fillColor: Theme.popoutBg
            strokeColor: Theme.popoutEdge
            strokeWidth: Theme.popoutBorder
            capStyle: ShapePath.FlatCap

            // A zero radius (no flare on an edge side) collapses the arc to nothing.
            readonly property real fL: root.leftFlare
            readonly property real fR: root.rightFlare
            readonly property real r: Theme.popoutRadius

            // Square on a flush side; a rounded corner would show a wedge of desktop.
            readonly property real rL:
                (root.atLeftEdge && Theme.popoutEdgeFlush) ? 0 : r
            readonly property real rR:
                (root.atRightEdge && Theme.popoutEdgeFlush) ? 0 : r

            readonly property real w: panelShape.width
            readonly property real h: panelShape.height

            startX: 0
            startY: 0

            // Top-left flare: clockwise, because this corner is concave.
            PathArc {
                x: outline.fL; y: outline.fL
                radiusX: outline.fL; radiusY: outline.fL
                direction: PathArc.Clockwise
            }

            PathLine { x: outline.fL; y: outline.h - outline.rL }

            PathArc {
                x: outline.fL + outline.rL; y: outline.h
                radiusX: outline.rL; radiusY: outline.rL
                direction: PathArc.Counterclockwise
            }

            PathLine { x: outline.w - outline.fR - outline.rR; y: outline.h }

            PathArc {
                x: outline.w - outline.fR; y: outline.h - outline.rR
                radiusX: outline.rR; radiusY: outline.rR
                direction: PathArc.Counterclockwise
            }

            PathLine { x: outline.w - outline.fR; y: outline.fR }

            // Top-right flare: mirror of the left.
            PathArc {
                x: outline.w; y: 0
                radiusX: outline.fR; radiusY: outline.fR
                direction: PathArc.Clockwise
            }
        }
    }

    // paddingRect gives the shadow room; without it the shadow is clipped.
    MultiEffect {
        source: panelShape
        anchors.fill: panelShape

        // Clamped at zero: a negative inset would shift the source inward and undo
        // the flush edge.
        readonly property int padLeft:  Math.max(0, root.leftInset)
        readonly property int padRight: Math.max(0, root.rightInset)

        paddingRect: Qt.rect(
            -padLeft,
            0,
            panelShape.width + padLeft + padRight,
            panelShape.height + Theme.popoutShadowMargin)

        shadowEnabled: true
        shadowColor: Theme.popoutShadowColor
        shadowOpacity: Theme.popoutShadowOpacity
        shadowBlur: Theme.popoutShadowBlur
        shadowVerticalOffset: Theme.popoutShadowOffsetY
        blurMax: Theme.popoutShadowMargin
    }

    Item {
        id: contentHolder

        anchors.fill: parent
        anchors.topMargin: 0
        anchors.bottomMargin: Theme.popoutShadowMargin
        anchors.leftMargin: root.leftPad
        anchors.rightMargin: root.rightPad
    }

    }
}
