#!/bin/bash
source "$CONFIG_DIR/colors.sh"
#
#
#
# # YABAI setup
#
#
SPACE_ICONS=("1" "2" "3" "4" "5" "6" "7" "8" "9" "10" "11" "12")
MAIN_DISPLAY=$(system_profiler SPDisplaysDataType | grep -B 3 'Main Display:' | awk '/Display Type/ {print $3}')

spacelabel=0
for i in "${!SPACE_ICONS[@]}"
do
  sid="$(($i+1))"

  spacelabel=$((spacelabel+1))
  # if [ "${MAIN_DISPLAY}" != "Built-in" ] && [ "$spacelabel" -gt 7 ]; then
  #   spacelabel=1
  # fi

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

## Aerosapce

# sketchybar --add event aerospace_workspace_change
#
# for sid in $(aerospace list-workspaces --all); do
#   sketchybar --add item space.$sid left \
#     --subscribe space.$sid aerospace_workspace_change \
#     --set space.$sid \
#     icon.font="$FONT:Normal:16.0" \
#     icon="$sid" \
#     icon.padding_left=10 \
#     icon.padding_right=10 \
#     background.color=$SURFACE0 \
#     background.corner_radius=5 \
#     background.height=24 \
#     background.drawing=off \
#     label.drawing=off \
#     label="$sid" \
#     click_script="aerospace workspace $sid" \
#     script="$PLUGIN_DIR/space.sh $sid"
#   done
