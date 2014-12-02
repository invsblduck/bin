#!/bin/sh

dir=/data
url=http://standards.ieee.org/regauth/oui/oui.txt

if ping -c2 -l2 -W2 8.8.8.8  |grep 64\ bytes; then
   if wget -P /tmp $url; then
      [ -f "$dir/oui.txt" ] && rm -f $dir/oui.txt
      mv /tmp/oui.txt $dir
   else
      echo "$0 unable to retrieve $url"
   fi
fi
