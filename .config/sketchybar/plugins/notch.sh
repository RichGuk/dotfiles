#!/bin/bash

# yabai runs this from launchd, where Homebrew is not on PATH.
export PATH="/opt/homebrew/bin:$PATH"

# safeAreaInsets.top is non-zero only on a notched display, and already accounts
# for the current scaled resolution, so it doubles as the bar height.
inset=$(osascript -l JavaScript -e 'ObjC.import("AppKit"); $.NSScreen.mainScreen.safeAreaInsets.top' 2>/dev/null)
inset=${inset%%.*}
[[ $inset =~ ^[0-9]+$ ]] || inset=0

# A notched display has no usable centre, so now-playing hides there. Nothing
# else differs: the bar carries no alias items, so sketchybar never screen-
# captures and the macOS recording indicator the clock used to dodge is gone.
if [ "$inset" -gt 0 ]; then
    height=$inset
    now_playing=off
else
    height=30
    now_playing=on
fi

sketchybar --bar height="$height" --set spotify drawing="$now_playing"
yabai -m config external_bar "main:$height:0" 2>/dev/null
