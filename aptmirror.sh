#!/bin/bash

set -e
if ! grep -qw /var/spool/apt-mirror /proc/mounts; then
    echo "mounting disk..."
    mount -L apt-mirror
fi

if [[ $1 =~ --?u(pdate)? ]]; then
    echo "running apt-mirror..."
    apt-mirror
fi

if ! pgrep lighttpd >/dev/null; then
    echo "starting lighttpd..."
    sudo systemctl start lighttpd
fi
