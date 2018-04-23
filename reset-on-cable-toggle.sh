#!/bin/bash 
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ "$(id -u)" != "0" ]; then 
        sudo $0 $@
        exit
fi

DEBUG=$1

echo_debug () {
	if [[ "$DEBUG" == "-v" ]]; then 
		echo "DEBUG: $*"
	fi
}

is_cable_plugged() {
 if [ "`ifconfig eth0|sed -n '/running/I p'`" == '' ];then echo no;else echo yes;fi
}


while true; do
	if [[ "$(is_cable_plugged)" == "no" ]]; then 
		while true; do
			if [[ "$(is_cable_plugged)" == "yes" ]]; then
				echo_debug "Cable is now connected, reloading networking..." 
                $DIR/reset-interfaces.sh
				break
			fi
			echo_debug "Waiting for cable to be connected..."
			sleep 1s
		done
	fi
	echo_debug "Cable is connected, do nothing..."
	sleep 1s
done
