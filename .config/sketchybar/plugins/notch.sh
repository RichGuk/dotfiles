#!/bin/bash

# yabai runs this from launchd, where Homebrew is not on PATH.
export PATH="/opt/homebrew/bin:$PATH"

# safeAreaInsets.top is non-zero only on a notched display, and already accounts
# for the current scaled resolution, so it doubles as the bar height.
inset=$(osascript -l JavaScript -e 'ObjC.import("AppKit"); $.NSScreen.mainScreen.safeAreaInsets.top' 2>/dev/null)
inset=${inset%%.*}
[[ $inset =~ ^[0-9]+$ ]] || inset=0

# A notched display has no usable centre, so now-playing hides there. The clock
# stays far right on every machine; clock_pad only keeps it clear of the macOS
# screen-recording indicator, which sits closer in on the narrower panel.
if [ "$inset" -gt 0 ]; then
    height=$inset
    now_playing=off
    clock_pad=20
else
    height=30
    now_playing=on
    clock_pad=8
fi

sketchybar --bar height="$height" \
    --set spotify drawing="$now_playing" \
    --set calendar padding_right="$clock_pad"
yabai -m config external_bar "main:$height:0" 2>/dev/null
