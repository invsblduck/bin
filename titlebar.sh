#!/bin/sh

# check for invocation
[ -z "$DISPLAY" ] && echo "you're not in X f00." && exit 1
[ -z "$1" ] && echo "you must supply string" && exit 1

# set xterm title and icon_name
print -Pn "\e]0;$*\a"
