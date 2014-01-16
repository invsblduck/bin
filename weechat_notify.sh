#!/bin/sh

title="$1"
body="$2"

notify-send -a weechat -i /usr/share/icons/hicolor/32x32/apps/weechat.png \
    "$title" "$body"
