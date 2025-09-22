#!/bin/sh

# sketchybar --set "$NAME" label="$(date '+ %a %d %b %H:%M')"

sketchybar --set $NAME icon="$(date '+%d %b')" label="$(date '+%H:%M')"
