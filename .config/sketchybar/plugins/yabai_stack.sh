#!/bin/bash
#
CURRENT=$(yabai -m query --windows --window 2>/dev/null | jq '.["stack-index"]')

if [[ $CURRENT -eq 0 ]]; then
  sketchybar --set yabai_stack label="" label.drawing=off
  exit 0
fi


LAST=$(yabai -m query --windows --window stack.last | jq '.["stack-index"]')

declare -a dots=()
for i in $(seq 0 $(expr $LAST - 1))
do  
  [[ $( expr $CURRENT - 1) -eq $i ]] && dots+="●" || dots+="○"
done

sketchybar --set yabai_stack label.font="FiraCode Nerd Font:Regular:16.0" label=$(printf "%s" ${dots[@]}) label.drawing=on
