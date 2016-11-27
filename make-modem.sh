#!/bin/bash 

INTERFACE="eth0"
VIRT_INT=":2"

if [ "$(id -u)" != "0" ]; then 
	sudo $0 $@
	exit
fi

user=$SUDO_USER
if [[ "$user" == "" ]]; then 
	user=$(whoami)
fi

script="$(basename $0)"
print_help () {
	cat <<HELP

Make eth0 as gateway, get internet from wlan0

usage:
	start:
		$script [ip-for-${INTERFACE}${VIRT_INT}]

	stop:
		$script stop
HELP
	exit
}

if [ "$1" != "" ]; then 
	eth_ip=$1
else
	eth_ip="172.17.0.1/24"
fi

ifconfig $INTERFACE up
ifconfig ${INTERFACE}${VIRT_INT} $eth_ip
echo "Using ${INTERFACE}${VIRT_INT}"
echo "Using $eth_ip"

echo "Clearing iptables"
iptables --table nat --flush 
iptables --flush 

if [ "$1" == "stop" ]; then 
        echo "disconnected frow wlan..."
        # we have disconnected earlier...
        exit 0
fi

echo "Making NAT configuration..."
iptables --table nat --append POSTROUTING --out-interface wlan0 -j MASQUERADE
iptables --append FORWARD --in-interface ${INTERFACE}${VIRT_INT} -j ACCEPT
echo 1 > /proc/sys/net/ipv4/ip_forward

echo "All settings are done"
echo "Setup clients to use $eth_ip as their gateway to connect to internet..."
echo 

