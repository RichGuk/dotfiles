#!/bin/bash

source "$CONFIG_DIR/colors.sh"

STATUS_LABEL=$(lsappinfo info -only StatusLabel "Slack")
ICON="󰒱"
ICON_COLOR=$TEXT

if [[ $STATUS_LABEL =~ \"label\"=\"([^\"]*)\" ]]; then
    LABEL="${BASH_REMATCH[1]}"

    if [[ $LABEL == "" ]]; then
        ICON_COLOR=$TEXT
    elif [[ $LABEL == "•" ]]; then
        ICON_COLOR=$TEXT
    elif [[ $LABEL =~ ^[0-9]+$ ]]; then
      ICON_COLOR=$RED
    else
        exit 0
    fi

    sketchybar --set $NAME icon=$ICON label="${LABEL}" label.drawing=off icon.color=${ICON_COLOR}
else
  exit 0
fi

