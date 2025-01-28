
#!/bin/bash
#
calendar=(
  icon.font="$FONT:Bold:14.0"
  icon.padding_right=0
  label.width=50
  label.align=right
  padding_left=0
  update_freq=10
  script="$PLUGIN_DIR/clock.sh"
)

sketchybar --add item calendar right --set calendar "${calendar[@]}"
