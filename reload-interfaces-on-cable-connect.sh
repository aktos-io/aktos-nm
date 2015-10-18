#!/bin/bash 

is_cable_plugged() {
 if [ "`ifconfig eth0|sed -n '/running/I p'`" == '' ];then echo no;else echo yes;fi
}


while true; do
	if [[ "$(is_cable_plugged)" == "no" ]]; then 
		while true; do
			if [[ "$(is_cable_plugged)" == "yes" ]]; then
				echo "DEBUG: Cable is now connected, reloading networking..." 
				rm /var/lib/dhcp/dhclient*
				/etc/init.d/networking reload
				#route add default gw 10.0.10.50 # needed if no dhcp server is present
				break
			fi
			echo "DEBUG: Waiting for cable to be connected..."
			sleep 1s
		done
	fi
	echo "DEBUG: Cable is connected, do nothing..."
	sleep 1s
done
