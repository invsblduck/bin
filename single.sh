#!/bin/sh
xrandr --output LVDS1 --primary --mode 1600x900 \
    --output HDMI1 --off \
    --output VGA1  --off \
    --output DP1   --off
