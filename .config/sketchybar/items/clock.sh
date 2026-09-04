#!/bin/bash

calendar=(
  icon.drawing=off
  label.font="$FONT:Bold:15.0"
  label.color=$BASE_TEXT
  padding_left=0
  update_freq=10 # position and padding_right are set per-display by plugins/notch.sh
  script="$PLUGIN_DIR/clock.sh"
)

sketchybar --add item calendar center --set calendar "${calendar[@]}"
