#!/bin/bash
# AeroSpace port of ~/.config/yabai/update_border_color.sh — hide the border
# when the workspace holds a single window, since there is nothing to disambiguate.

n=$(aerospace list-windows --workspace focused --count 2>/dev/null)

if [ "$n" = 1 ]; then
    borders active_color=0x00000000 inactive_color=0x00000000
else
    borders active_color=0xffcba6f7 inactive_color=0xff1e1e2e
fi
