#!/bin/bash

TITLE=Monolith
START=/data/kajabi/monolith/start.sh
STOP=/data/kajabi/monolith/stop.sh
ATTACH="tmux attach -t ${TITLE}"

# Stop monolith and exit script?
if [ "$1" = stop ]; then
    ${STOP}
    exit 0
fi

# Check whether it's already running.
#
#   This will determine whether we attach existing tmuxinator session or
#   create a new one.
#
if tmux ls -F '#{session_name}' |grep -xF "${TITLE}"; then
    CMD="${ATTACH}"
else
    CMD="${START}"
fi

# If actually seated at this computer, search for existing terminal window :)
if [ -n "${DISPLAY}" -a "${DISPLAY}" = :0 ]; then
    if xwininfo -name "${TITLE}"
    then
        # Focus and raise existing window
        wmctrl -a "${TITLE}" -F
    else
        # Start new window
        xfce4-terminal --title "${TITLE}" \
                       --icon ~/Pictures/emoji/ruby.png \
                       --hide-menubar \
                       --hide-toolbar \
                       --hold \
                       --maximize \
                       -x ${CMD}
    fi

else
    # Start or attach session in current TTY
    ${CMD}
fi

