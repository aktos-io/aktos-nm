#!/bin/bash 
rm /var/lib/dhcp/dhclient* 2> /dev/null

iface="eth0"
echo "Requesting DHCP for $iface"
#/etc/init.d/networking reload
timeout 5s dhclient $iface 2> /dev/null
[[ "$?" == "0" ]] || echo "..failed getting dhcp response for $iface"
