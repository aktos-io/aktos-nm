#!/bin/bash 

function list_clients() {
	echo "List of dhcp clients: "
	echo "----------------------"
	cat /var/lib/misc/dnsmasq.leases
}



user=$SUDO_USER
if [[ "$user" == "" ]]; then 
	user=$(whoami)
fi
CONF_DIR="/home/$user/.cca/wifi-conf.d/"


script="$(basename $0)"
if [[ "$1" == "" ]]; then 
	cat <<HELP

usage:
	connect:
		$script config_name

	scan:
		$script scan

	add:
		$script add my_essid passwd [custom name]

	list-clients:
		$script list-clients


HELP
	exit
fi

CMD=$1

if [[ "$CMD" == "search" ]] || [[ "$CMD" == "scan" ]]; then 
	iwlist wlan0 scan | grep -i essid | more
elif [[ "$CMD" == "add" ]]; then 
	essid=$2
	passwd=$3
	if [[ "$essid" == "" ]] || [[ "$passwd" == "" ]]; then 
		echo "usage: "
		echo ""
		echo "    $(basename $0) add my_essid my_passwd [custom_name]"
		exit
	fi
	conf_name=$4
	if [[ "$conf_name" == "" ]]; then 
		conf_name=$essid
	fi
	wpa_passphrase $essid $passwd > $CONF_DIR/$conf_name.conf
	read -p "Press [Enter] key to connect to $conf_name..."
        sudo bash -c "$0 $conf_name"
elif [[ "$CMD" == "list-clients" ]]; then 
	list_clients
	exit 0 
fi

CONF=$1

if [[ "$CONF" == "" ]]; then
	echo "You need to supply a config name!"
	echo "exiting..."
	exit 1
fi 



if [ "$(id -u)" -ne "0" ]; then 
        echo "Run this script with root priviliges"
        sudo bash -c "$0 $1 $2"
        exit
fi

echo "Making NAT configuration..."

echo "Stopping network manager"
/etc/init.d/network-manager stop
killall wpa_supplicant 

ifconfig eth0 10.0.10.50/24
/etc/init.d/dnsmasq restart

echo "connecting to wifi 3gconnect"
wpa_supplicant -c"$CONF_DIR/$CONF.conf" -Dwext -iwlan0 &
sleep 5
dhclient wlan0


echo "Clearing iptables"
iptables --table nat --flush 
iptables --flush 

iptables --table nat --append POSTROUTING --out-interface wlan0 -j MASQUERADE

iptables --append FORWARD --in-interface eth0 -j ACCEPT

echo 1 > /proc/sys/net/ipv4/ip_forward

#/etc/init.d/networking reload

list_clients 

echo "All settings are done..."


