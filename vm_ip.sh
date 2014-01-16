#!/bin/sh

[ -z "$1" ] && echo "usage: ${0##*/} <name>" && exit 1

mac=$(sudo virsh domiflist $1 |grep : |awk '{print $5}')
[ -z "$mac" ] && echo "couldn't find mac address for domain $1 :(" && exit 1

grep " $mac " /var/lib/libvirt/dnsmasq/*.leases |awk '{print $3}'
