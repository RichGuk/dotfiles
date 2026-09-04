#!/bin/bash

meeting=(
  icon=""
  icon.font="$FONT:Regular:14.0"
  icon.color=$BASE_TEXT
  icon.padding_left=10
  icon.padding_right=7
  label.font="$FONT:Bold:14.0"
  label.color=$BASE_TEXT
  label.padding_right=10
  padding_left=12
  padding_right=12
  background.color=$BASE
  background.corner_radius=5
  background.height=24
  drawing=off
  update_freq=30
  script="$PLUGIN_DIR/meeting.sh"
)

sketchybar --add item meeting right --set meeting "${meeting[@]}" \
  --subscribe meeting mouse.clicked
