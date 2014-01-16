#!/bin/sh
#out=HDMI1
#side=--left-of
#[ "$1" = "vga" ] && out=VGA1
#[ "$2" = "right" ] && side=--right-of
#[ "$2" = "left" ] && side=--left-of
#xrandr --output $out --auto $side LVDS1 --output LVDS1 --auto
xrandr --output VGA1 --mode 1024x768 --output LVDS1 --mode 1024x768
