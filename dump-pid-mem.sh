#!/bin/bash

[ -z "$1" ] && echo "usage: $0 {PID}" && exit 1

#grep rw-p /proc/$1/maps \
#    |sed -n 's/^\([0-9a-f]*\)-\([0-9a-f]*\) .*$/\1 \2/p' \
#    |while read start stop; do \
#        gdb --batch --pid $1 -ex \
#            "dump memory $1-$start-$stop.dump 0x$start 0x$stop"; \
#    done

cat /proc/$1/maps | grep -Fv ".so" | grep " 0 " | awk '{print $1}' | ( IFS="-"
while read a b; do
dd if=/proc/$1/mem bs=4096 iflag=skip_bytes,count_bytes \
   skip=$(( 0x$a )) count=$(( 0x$b - 0x$a )) of="$1_mem_$a.bin"
done )
