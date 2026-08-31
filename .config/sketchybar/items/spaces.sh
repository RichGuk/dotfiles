#!/bin/bash
source "$CONFIG_DIR/colors.sh"

# AeroSpace emulates workspaces rather than using macOS Spaces, so these are
# plain items driven by aerospace_workspace_change, not sketchybar `space` items.
# The list mirrors workspace-to-monitor-force-assignment in aerospace.toml:
# 1-9 on the main display, Q and W on the secondary.
WORKSPACES=(1 2 3 4 5 6 7 8 9 Q W)

sketchybar --add event aerospace_workspace_change

for sid in "${WORKSPACES[@]}"; do
  sketchybar --add item space."$sid" left \
    --subscribe space."$sid" aerospace_workspace_change \
    --set space."$sid" \
    icon.font="$FONT:Normal:16.0" \
    icon="$sid" \
    icon.padding_left=10 \
    icon.padding_right=10 \
    background.color=$SURFACE0 \
    background.corner_radius=5 \
    background.height=24 \
    background.drawing=off \
    label.drawing=off \
    click_script="aerospace workspace $sid" \
    script="$PLUGIN_DIR/space.sh $sid"
done
