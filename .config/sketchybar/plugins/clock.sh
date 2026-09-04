#!/bin/sh

# One string, no icon: the item is centred, and a leading glyph would centre the
# glyph+text pair rather than the time itself. Matches the Quickshell bar.
sketchybar --set "$NAME" label="$(date '+%a, %d. %b %I:%M %p')"
