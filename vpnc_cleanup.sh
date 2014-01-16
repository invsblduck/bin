#!/bin/sh

if ! pgrep vpnc >/dev/null; then
    if [ -e /run/resolvconf/interfaces/tun0 ]; then
        sudo resolvconf -d tun0
    fi
fi
