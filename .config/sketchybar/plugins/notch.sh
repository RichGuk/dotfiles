#!/bin/bash

# yabai runs this from launchd, where Homebrew is not on PATH.
export PATH="/opt/homebrew/bin:$PATH"

# safeAreaInsets.top is non-zero only on a notched display, and already accounts
# for the current scaled resolution, so it doubles as the bar height.
inset=$(osascript -l JavaScript -e 'ObjC.import("AppKit"); $.NSScreen.mainScreen.safeAreaInsets.top' 2>/dev/null)
inset=${inset%%.*}
[[ $inset =~ ^[0-9]+$ ]] || inset=0

# A notched display has no usable centre, so the clock goes back to the right
# and now-playing hides; docked, the clock is the fixed centre point like the
# Quickshell bar. clock_pad keeps it clear of the screen-recording indicator.
if [ "$inset" -gt 0 ]; then
    height=$inset
    now_playing=off
    clock_pos=right
    clock_pad=20
else
    height=30
    now_playing=on
    clock_pos=center
    clock_pad=0
fi

sketchybar --bar height="$height" \
    --set spotify drawing="$now_playing" \
    --set calendar position="$clock_pos" padding_right="$clock_pad"
yabai -m config external_bar "main:$height:0" 2>/dev/null
