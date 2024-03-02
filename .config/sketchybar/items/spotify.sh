#!/bin/bash

SPOTIFY_EVENT="com.spotify.client.PlaybackStateChanged"

spotify=(
  padding_right=20
  icon=
  icon.font="FiraCode Nerd Font:Regular:16.0"
  icon.padding_left=8
  icon.padding_right=10
  label.drawing=off
  label.padding_left=-5
  label.padding_right=8
  background.corner_radius=5
  background.height=24
  script="$PLUGIN_DIR/spotify.sh"
)

sketchybar --add event spotify_change $SPOTIFY_EVENT --add item spotify right \
  --set spotify "${spotify[@]}" --subscribe spotify spotify_change
