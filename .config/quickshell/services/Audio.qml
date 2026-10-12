pragma Singleton

// Volume via Quickshell's Pipewire service.
// PwNodeAudio's properties all read as zero unless the node is bound by a
// PwObjectTracker -- that is what the trackers below are for.

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    // ------------------------------------------------------------------
    // The default output, and its input counterpart.
    // ------------------------------------------------------------------
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    readonly property bool ready: Pipewire.ready && !!sink && !!sink.audio

    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    // ------------------------------------------------------------------
    // Output. Volume is 0..1.
    // ------------------------------------------------------------------
    readonly property real volume: ready ? sink.audio.volume : 0
    readonly property bool muted: ready ? sink.audio.muted : true
    readonly property int volumePercent: Math.round(volume * 100)

    function setVolume(v) {
        if (!ready) return;
        // Clamped: pipewire accepts >1.0 as software boost.
        root.sink.audio.volume = Math.max(0, Math.min(1, v));
    }

    function setVolumePercent(p) {
        root.setVolume(p / 100);
    }

    function toggleMute() {
        if (!root.ready) return;
        root.sink.audio.muted = !root.sink.audio.muted;
    }

    readonly property string glyphName:
        muted ? "volumeMuted"
        : volume < 0.01 ? "volumeMuted"
        : volume < 0.34 ? "volumeLow"
        : volume < 0.67 ? "volumeMed"
        : "volume"

    // ------------------------------------------------------------------
    // Input, for the microphone row.
    // ------------------------------------------------------------------
    readonly property bool sourceReady: Pipewire.ready && !!source && !!source.audio
    readonly property real sourceVolume: sourceReady ? source.audio.volume : 0
    readonly property bool sourceMuted: sourceReady ? source.audio.muted : true

    function setSourceVolume(v) {
        if (!root.sourceReady) return;
        root.source.audio.volume = Math.max(0, Math.min(1, v));
    }

    function toggleSourceMute() {
        if (!root.sourceReady) return;
        root.source.audio.muted = !root.source.audio.muted;
    }

    // ------------------------------------------------------------------
    // Output devices, for switching. `isStream` excludes app streams.
    // ------------------------------------------------------------------
    readonly property var sinks: {
        const out = [];
        for (const n of Pipewire.nodes.values) {
            if (n.isSink && !n.isStream) out.push(n);
        }
        // Sorted, or rows reshuffle as devices come and go.
        out.sort((a, b) => root.label(a).localeCompare(root.label(b)));
        return out;
    }

    PwObjectTracker {
        objects: root.sinks
    }

    function setSink(node) {
        // preferredDefaultAudioSink is the writable one; defaultAudioSink is read-only.
        Pipewire.preferredDefaultAudioSink = node;
    }

    function isCurrentSink(node) {
        return !!node && !!root.sink && node.id === root.sink.id;
    }

    function label(node) {
        if (!node) return "";
        return node.description || node.name || "Unknown output";
    }
}
