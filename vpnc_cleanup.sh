#!/bin/sh

if ! pgrep vpnc >/dev/null; then
    for iface in tun0 enp0s3 eth0; do
        if [ -e /run/resolvconf/interfaces/$iface ]; then
            sudo resolvconf -d $iface
        fi
    done
fi
