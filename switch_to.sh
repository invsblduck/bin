#!/bin/bash

iface=wlp4s0

sudo netctl stop-all
sudo iwconfig $iface power off
sudo ip link set $iface down

name=$(basename ${0##*/} .sh)
for i in {1..3}; do
    sudo netctl switch-to $name
    if [ $? = 0 ]; then
        ichk
        exit $?
    fi
done

journalctl -xab |less +G    
