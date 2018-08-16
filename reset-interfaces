#!/bin/bash 
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR/aktos-bash-lib/basic-functions.sh

echo "Removing lease files..."
rm /var/lib/dhcp/dhclient* 2> /dev/null

iface="eth0"
#/etc/init.d/networking reload
dhclient -r $iface # killing old client
ifconfig $iface down
ifconfig $iface up
echo "Requesting DHCP for $iface"
timeout 5s dhclient -v $iface 2> /dev/null
[[ "$?" == "0" ]] || echo "..failed getting dhcp response for $iface"
