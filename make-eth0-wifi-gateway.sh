#!/bin/bash 

IFACE_TO_MAKE_GATEWAY="eth0"
IFACE_TO_GET_INTERNET="wlp2s0"

I_SERVER="$IFACE_TO_MAKE_GATEWAY"
I_CLIENT="$IFACE_TO_GET_INTERNET"

if [[ "$1" == "" ]]; then 
    echo "first parameter should be ip address of $I_SERVER"
    exit 
fi 

IP=$1

if [ "$(id -u)" != "0" ]; then 
	sudo $0 $@
	exit
fi

echo "Clearing iptables"
iptables --table nat --flush 
iptables --flush 

echo "Making $I_SERVER gateway..."
ifconfig $I_SERVER up
ifconfig $I_SERVER $IP

echo "...making NAT configuration..."
iptables --table nat --append POSTROUTING --out-interface $I_CLIENT -j MASQUERADE
iptables --append FORWARD --in-interface $I_SERVER -j ACCEPT
echo 1 > /proc/sys/net/ipv4/ip_forward

echo "All settings are done"
echo "Setup clients to use $IP as their gateway to connect to internet..."
echo

