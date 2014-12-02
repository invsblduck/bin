#!/bin/sh

# use eth0 by default
if [ -z "$1" ]; then
   iface=eth0
else
   iface=$1
fi

# shutdown interface
#echo "Bringing down interface $iface ..." 
/usr/bin/sudo /sbin/ifconfig $iface down

# assign a new mac address >:)
read -p "New MAC address for $iface: " mac
echo "Remapping $iface hwaddr to $mac ..."
/usr/bin/sudo /sbin/ifconfig $iface hw ether "$mac"

# get rid of dhcp lease information/cache
echo "Destroying DHCP cache..."
#/usr/bin/sudo /bin/rm -f /etc/dhcpc/*${iface}*
/usr/bin/sudo /bin/rm -f /var/run/pump*

# bring up interface 
echo "Broadcasting DHCP discover messages..."
#/usr/bin/sudo /sbin/pump -k >/dev/null 2>&1
#/bin/sleep 2
/usr/bin/sudo /sbin/pump -i $iface && echo "bound to `myip.sh $iface`"

#echo -n "Your new IP address is "
#/sbin/ifconfig "$iface" \
#  |/bin/egrep inet \
#  |/usr/bin/awk '{ print $2 }' \
#  |/usr/bin/cut -f2 -d':'
