#!/bin/bash

TITLE=Emacs

# Terminal window already running?
if xwininfo -name "${TITLE}"
then
    # Focus and raise window
    wmctrl -a "${TITLE}" -F
    exit 0
fi


# Start new terminal with dedicated tmux session
xfce4-terminal --title "${TITLE}" \
               --icon /usr/share/icons/hicolor/48x48/apps/emacs.png \
               --hide-menubar \
               --hide-toolbar \
               --hold \
               --geometry 120x45 \
               --zoom 2 \
               -x tmux -u -2 \
                   new-session -AX -s "${TITLE}" emacsclient -t

