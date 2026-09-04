#!/bin/bash

calendar=(
  icon.drawing=off
  label.font="$FONT:Bold:15.0"
  padding_left=16
  update_freq=10 # padding_right is set per-display by plugins/notch.sh
  script="$PLUGIN_DIR/clock.sh"
)

# Sourced before the other right-hand items, which stack right-to-left, so this
# ends up furthest right.
sketchybar --add item calendar right --set calendar "${calendar[@]}"
