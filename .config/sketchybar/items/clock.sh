#!/bin/bash

calendar=(
  icon.drawing=off
  label.font="$FONT:Bold:15.0"
  padding_left=16
  padding_right=2 # the bar adds 10 of its own
  update_freq=10
  script="$PLUGIN_DIR/clock.sh"
)

# Sourced before the other right-hand items, which stack right-to-left, so this
# ends up furthest right.
sketchybar --add item calendar right --set calendar "${calendar[@]}"
