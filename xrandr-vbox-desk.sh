#!/bin/sh

##
# Right monitor rotated 90 degrees (PITA)
#xrandr --output VBOX0 --mode 1920x1015 --pos 0x420 --primary \
#       --output VBOX1 --mode 1080x1855 --pos 1920x0

##
# Both monitors in standard orientation
xrandr --output VBOX0 --auto --primary \
       --output VBOX1 --auto --right-of VBOX0
