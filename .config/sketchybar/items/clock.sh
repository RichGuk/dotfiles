
#!/bin/bash
#
calendar=(
  icon.font="$FONT:Regular:16.0"
  label.font="$FONT:bold:16.0"
  icon.padding_right=6 # gap between the date (icon) and the time (label)
  label.width=50
  label.align=right
  padding_left=0
  update_freq=10
  script="$PLUGIN_DIR/clock.sh"
)

sketchybar --add item calendar right --set calendar "${calendar[@]}"
