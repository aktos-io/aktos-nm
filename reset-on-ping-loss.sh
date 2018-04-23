#!/bin/bash 
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR/aktos-bash-lib/basic-functions.sh

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

is_network_reachable() {
   /bin/ping -c1 -w1 aktos.io &> /dev/null
}

server="aktos.io"
echo "Starting daemon..."
published_reachable=
while true; do
	if ! is_network_reachable; then 
        echo "Network seems not reachable, waiting for 10 seconds for refreshing connection"
        published_reachable=
        $DIR/reset-interfaces.sh
	else
    	[ -z $published_reachable ] && echo_green "Network is reachable, doing nothing."
        published_reachable="yes"
	    sleep 5s
    fi
done
