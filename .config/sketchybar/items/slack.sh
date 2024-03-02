#!/bin/bash
#
slack=(
  update_freq=180
  padding_left=0
  padding_right=0
  icon.padding_left=5
  icon.padding_right=5
  script="$PLUGIN_DIR/slack.sh"
)

sketchybar --add item slack right --set slack "${slack[@]}" --subscribe slack system_woke
