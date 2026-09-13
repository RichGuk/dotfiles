#!/bin/bash

source "$CONFIG_DIR/colors.sh"

PERCENTAGE="$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)"
CHARGING="$(pmset -g batt | grep 'AC Power')"

if [ "$PERCENTAGE" = "" ]; then
  exit 0
fi

# Same ramps and thresholds as the Quickshell bar (theme/Theme.qml), so both
# machines speak the same battery vocabulary. Index is floor(percent/10), so 62%
# draws the 60% glyph and only a true 100% draws the full one.
RAMP=(󰁺 󰁻 󰁼 󰁽 󰁾 󰁿 󰂀 󰂁 󰂂 󰁹)
CHARGING_RAMP=(󰢜 󰂆 󰂇 󰂈 󰢝 󰂉 󰢞 󰂊 󰂋 󰂅)

IDX=$((PERCENTAGE / 10))
[ "$IDX" -gt 9 ] && IDX=9

if [ -n "$CHARGING" ]; then
  ICON="${CHARGING_RAMP[$IDX]}"
else
  ICON="${RAMP[$IDX]}"
fi

COLOR=$TEXT
[ "$PERCENTAGE" -le 20 ] && COLOR=$RED # Theme.batteryWarnAt

sketchybar --set "$NAME" icon="$ICON" label="${PERCENTAGE}%" label.color=$COLOR icon.color=$COLOR
