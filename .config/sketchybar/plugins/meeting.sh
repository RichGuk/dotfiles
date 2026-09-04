#!/bin/bash

# sketchybar runs plugins from launchd, where Homebrew (and so gog) is not on PATH.
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

NEXT="$HOME/Scripts/next-meeting"

if [ "$SENDER" = "mouse.clicked" ]; then
    url=$("$NEXT" --url)
    [ -n "$url" ] && open "$url"
    exit 0
fi

label=$("$NEXT")

if [ -n "$label" ]; then
    sketchybar --set "$NAME" drawing=on label="$label"
else
    sketchybar --set "$NAME" drawing=off
fi
