#!/bin/sh
if [ ! -e /dev/sr0 ]; then
    echo 0 0 0 | sudo tee /sys/class/scsi_host/host*/scan
    sleep 1
fi
mount /mnt/cdrom
