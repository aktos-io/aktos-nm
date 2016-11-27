#!/bin/bash 

if [ "$(id -u)" != "0" ]; then 
        sudo $0 $@
        exit 
fi

user=$SUDO_USER
if [[ "$user" == "" ]]; then 
	user=$(whoami)
fi

script="$(basename $0)"

function print_usage {
if [[ "$1" == "" ]]; then 
	cat <<HELP

usage:
	scan:
		$script 

	add:
		$script ESSID PASSWD [CONFIG_FILE]
HELP
	exit
fi

}

if [[ "$1" == "" ]]; then
	echo "searching for wireless networks..."
	iwlist wlan0 scan | grep -i essid | more
else
	essid=$1
	passwd=$2
	if [[ "$essid" == "" ]] || [[ "$passwd" == "" ]]; then 
		print_usage
	fi

	# print and maybe save 
	conf_name=$3
	wpa_passphrase $essid $passwd | tee $conf_name
fi

