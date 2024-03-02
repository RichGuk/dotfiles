#!/bin/bash
#
source "$CONFIG_DIR/colors.sh"

SPACE_ICONS=("1" "2" "3" "4" "5" "6" "7" "8" "9" "10" "11" "12")

spacelabel=0
for i in "${!SPACE_ICONS[@]}"
do
  sid="$(($i+1))"

  spacelabel=$((spacelabel+1))
  if [ "$spacelabel" -gt 6 ]; then
    spacelabel=1
  fi

  space=(
    space="$sid"
    icon.font="$FONT:Normal:16.0"
    icon="$spacelabel"
    icon.padding_left=10
    icon.padding_right=10
    background.color=$SURFACE0
    background.corner_radius=5
    background.height=24
    label.drawing=off
    script="$PLUGIN_DIR/space.sh"
    click_script="yabai -m space --focus $sid"
  )
  sketchybar --add space space."$sid" left --set space."$sid" "${space[@]}"
done
