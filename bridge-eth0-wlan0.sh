#!/bin/bash 

if [ "$(id -u)" -ne "0" ]; then 
        echo "Run this script with root priviliges"
        sudo bash -c "$0 $*"
        exit
fi


function list_clients() {
	echo "List of dhcp clients: "
	echo "----------------------"
	cat /var/lib/misc/dnsmasq.leases
}


if [[ "$user" == "" ]]; then 
    user=$SUDO_USER
    echo "USER IS: $user"
    echo "PARAMS: $*"
    if [[ "$user" == "" ]]; then 
    	user=$(whoami)
    fi
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

    stop: 
        $script stop


HELP
	exit
fi

CMD=$1

ifconfig wlan0 up 
sleep 0.5

if [[ "$CMD" == "search" ]] || [[ "$CMD" == "scan" ]]; then 
	iwlist wlan0 scan | grep -i essid | more
    exit 
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
    echo "Conf Name is: $conf_name"
	wpa_passphrase $essid $passwd > $CONF_DIR/$conf_name.conf
	read -p "Press [Enter] key to connect to $conf_name..."
    echo "0 is: $0, conf_name is $conf_name"
    sudo bash -c "user=$user $0 $conf_name"
    exit 0 
elif [[ "$CMD" == "list-clients" ]]; then 
	list_clients
	exit 0 
elif [[ "$CMD" == "stop" ]]; then 
    /etc/init.d/dnsmasq stop
    iptables --flush
    iptables --flush --table nat
    dhclient -r 
    exit 0 
fi

CONF=$1

if [[ "$CONF" == "" ]]; then
	echo "You need to supply a config name!"
	echo "exiting..."
	exit 1
fi 




echo "Using following credentials: " 
CONFIG="$CONF_DIR/$CONF.conf"
cat $CONFIG | grep ssid

ifconfig wlan0 up 

echo "Making NAT configuration..."

echo "Stopping network manager"
/etc/init.d/network-manager stop
killall wpa_supplicant 

echo "Renewing DHCP lease..."
dhclient -r

ifconfig eth0 172.17.0.1/24
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


