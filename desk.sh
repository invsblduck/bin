#!/bin/sh

xrandr --output HDMI1 --auto --primary \
       --output LVDS1 --mode 1600x900 --left-of HDMI1
