#!/bin/bash

sketchybar --add event window_focus --add event space_changed --add event mode_change

yabai=(
label.font="FiraCode Nerd Font:Regular:16.0"
  script="$PLUGIN_DIR/yabai_mode.sh"
)
sketchybar --add item yabai_mode left \
  --set yabai_mode "${yabai[@]}" \
  --subscribe yabai_mode mode_change space_changed


yabai_stack=(
  label.drawing=off
  update_freq=0
  script="$PLUGIN_DIR/yabai_stack.sh"
)
sketchybar --add item yabai_stack left \
  --set yabai_stack "${yabai_stack[@]}" \
  --subscribe yabai_stack space_changed window_focus mode_change
