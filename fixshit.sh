#!/bin/sh
#echo 0 |sudo tee /sys/class/backlight/intel_backlight/brightness
setxkbmap dvorak
xmodmap /home/duck/.xmodmaprc
xset r rate 170 150
#xrandr --output DP1 --primary --mode 1920x1080 --output LVDS1 --mode 1366x768 --below DP1
sudo iwconfig wlp4s0 power off
