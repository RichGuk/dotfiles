pragma Singleton

// Now playing, from MPRIS. `track` is null when nothing is playing.

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    // ------------------------------------------------------------------
    // Which player: Playing beats Paused. playerctld is skipped -- it mirrors
    // another player, so leaving it in shows the same track twice.
    // ------------------------------------------------------------------
    readonly property var player: {
        const all = Mpris.players ? Mpris.players.values : [];
        let paused = null;

        for (const candidate of all) {
            if (!candidate) continue;
            if ((candidate.dbusName || "").indexOf("playerctld") !== -1) continue;

            if (candidate.playbackState === MprisPlaybackState.Playing) return candidate;
            if (!paused && candidate.playbackState === MprisPlaybackState.Paused) {
                paused = candidate;
            }
        }
        return paused;
    }

    readonly property bool playing:
        !!player && player.playbackState === MprisPlaybackState.Playing

    // ------------------------------------------------------------------
    // The track. Every field is defaulted: players omit album, length, etc.
    // ------------------------------------------------------------------
    readonly property var track: player ? ({
        playing:      root.playing,
        title:        player.trackTitle  || "Unknown track",
        artist:       player.trackArtist || "",
        album:        player.trackAlbum  || "",

        // Gate on lengthSupported, not length != 0: with no mpris:length,
        // Quickshell returns the position as the length.
        lengthSec:    player.lengthSupported ? (player.length || 0) : 0,

        artUrl:       player.trackArtUrl || "",
        desktopEntry: player.desktopEntry || ""
    }) : null

    readonly property bool canGoNext:     !!player && player.canGoNext
    readonly property bool canGoPrevious: !!player && player.canGoPrevious
    readonly property bool canToggle:     !!player && player.canTogglePlaying

    // ------------------------------------------------------------------
    // Position. MPRIS does not push position, so poll while playing.
    // ------------------------------------------------------------------
    property int positionSec: 0

    function syncPosition() {
        if (!player || !player.positionSupported) {
            positionSec = 0;
            return;
        }
        // Emitting the notify signal makes Quickshell re-read from the player;
        // without it `position` returns the cached value.
        player.positionChanged();
        positionSec = Math.max(0, Math.floor(player.position || 0));
    }

    Timer {
        running: root.playing
        interval: 1000
        repeat: true
        onTriggered: root.syncPosition()
    }


    // The Timer is stopped while paused, but a seek or track change still needs a sync.
    onPlayerChanged: syncPosition()
    onPlayingChanged: syncPosition()

    // ------------------------------------------------------------------
    // Transport, guarded on the player's capability flags.
    // ------------------------------------------------------------------
    function togglePlaying() {
        if (player && player.canTogglePlaying) player.togglePlaying();
    }

    function next() {
        if (player && player.canGoNext) player.next();
    }

    function previous() {
        if (player && player.canGoPrevious) player.previous();
    }

    function formatDuration(totalSeconds) {
        const mins = Math.floor(totalSeconds / 60);
        const secs = Math.floor(totalSeconds % 60);
        return mins + ":" + String(secs).padStart(2, "0");
    }
}
