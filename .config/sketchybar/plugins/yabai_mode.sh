#!/bin/bash

yabai_mode=$(yabai -m query --spaces --space | jq -r .type)

case "$yabai_mode" in
    bsp)
    sketchybar --set yabai_mode label="󰝘"
    ;;
    stack)
    sketchybar --set yabai_mode label=""
    ;;
    float)
    sketchybar --set yabai_mode label=""
    ;;
esac
