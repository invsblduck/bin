#!/bin/sh

xrandr --output VGA1 --auto --primary \
       --output LVDS1 --mode 1600x900 --below VGA1
