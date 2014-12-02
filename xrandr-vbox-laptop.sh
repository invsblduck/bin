#!/bin/sh
# Mirror the displays
xrandr --output VBOX0 --auto --primary \
       --output VBOX1 --auto --same-as VBOX0
