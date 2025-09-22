#!/bin/bash

source "$CONFIG_DIR/colors.sh"

battery=(
  update_freq=120
  font="$FONT:Regular:16.0"
  script="$PLUGIN_DIR/battery.sh"
  icon.padding_right=3
  label.padding_left=5
  label.padding_right=0
  padding_left=15
  padding_right=5
)
#
sketchybar --add item battery right --set battery "${battery[@]}" --subscribe battery system_woke power_source_change
