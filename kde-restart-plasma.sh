#!/bin/bash

# KDE 4
# killall plasma-desktop
# kstart plasma-desktop


# KDE 5
# killall plasmashell
# kstart plasmashell

# 5.10+
kquitapp5 plasmashell || killall plasmashell \
    && kstart5 plasmashell
