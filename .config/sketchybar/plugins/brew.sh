#!/bin/bash

source "$CONFIG_DIR/colors.sh"

COUNT="$(brew outdated | wc -l | tr -d ' ')"

COLOR=$RED
DRAWING="on"

case "$COUNT" in
  [3-5][0-9]) COLOR=$RED
  ;;
  [1-2][0-9]) COLOR=$YELLOW
  ;;
  [1-9]) COLOR=$TEXT
  ;;
  0) COLOR=$TEXT
     COUNT=""
     DRAWING="off"
  ;;
esac

sketchybar --set $NAME label=$COUNT label.drawing=${DRAWING} icon.color=$COLOR
