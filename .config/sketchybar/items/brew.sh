#!/bin/bash

brew=(
  update_freq=86400
  icon="􀐛"
  script="$PLUGIN_DIR/brew.sh"
  label.drawing=off
  padding_right=3
  icon.font.size=14.0
)

sketchybar --add event brew_update \
           --add item brew right   \
           --set brew "${brew[@]}" \
           --subscribe brew brew_update
