#!/bin/bash
# Force running as root 
if [ "$(whoami)" != "root" ]; then
  echo "Run as root."
  exit
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source $DIR/aktos-bash-lib/basic-functions.sh


list_interfaces(){
    ifconfig -a  | egrep "^[a-z]+" | sed "s/: .*//" | grep -v "lo"
}

show_help() {
    cat <<HELP
    Usage:

        sudo $(basename $0) --wan wlp2s0 --lan eth0 --ip 10.0.8.50

    Options:
    --wan       : WAN interface (the interface which has a working internet connection)
    --lan       : LAN interface (the interface that will act as a modem)
    --ip   	: Desired IP address of LAN interface

    Currently available interfaces on $(hostname):

$(list_interfaces | indent | indent | indent )

HELP
}

die () {
    if [[ "$@" ]]; then
        errcho "ERROR: "
        errcho "ERROR: $@"
        errcho "ERROR: "
    fi
    echo
    show_help
    exit 5
}

while :; do
    case $1 in
        -h|-\?|--help)
            show_help    # Display a usage synopsis.
            exit
            ;;
        --wan)       # Takes an option argument; ensure it has been specified.
            if [ "$2" ]; then
                WAN=$2
                shift
            fi
            ;;
        --lan)       # Takes an option argument; ensure it has been specified.
            if [ "$2" ]; then
                LAN=$2
                shift
            fi
            ;;
        --ip)       # Takes an option argument; ensure it has been specified.
            if [ "$2" ]; then
                LAN_IP=$2
                shift
            fi
            ;;
        -?*)
            printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
            ;;
        *)               # Default case: No more options, so break out of the loop.
            break
    esac

    shift
done

#echo "DEBUG: WAN: $WAN, LAN: $LAN, LAN_IP: $LAN_IP"
curr_interfaces=$(list_interfaces)

contains(){
    list=$1
    x=$2
    [[ $list =~ (^|[[:space:]])"$x"($|[[:space:]]) ]] && echo "yes" || echo "no"
}

# check required parameters
[ -z $WAN ] && die "WAN interface is required."
[[ $(contains "$curr_interfaces" "$WAN") == "yes" ]] || die  "No such WAN interface can be found: $WAN"

[ -z $LAN ] && die "LAN interface is required."
[[ $(contains "$curr_interfaces" "$LAN") == "yes" ]] || die  "No such LAN interface can be found: $LAN"

[ -z $LAN_IP ] && die "LAN interface IP is required."

LAN_IP="$LAN_IP/24"

echo_green "Using $WAN as WAN, $LAN as LAN and $LAN_IP as IP of $LAN."

ifconfig $LAN up
ifconfig $LAN $LAN_IP

echo 1 > /proc/sys/net/ipv4/ip_forward
sysctl -w net.ipv4.ip_forward=1 > /dev/null

echo "Clearing iptables"
iptables -F
iptables -t nat -F
iptables -t mangle -F
iptables -X

#
# Debug logging
#iptables -I INPUT 1 --source 130.235.35.233/31 -j LOG --log-prefix "INPUT: "
#iptables -I FORWARD 1 --source 130.235.35.233/31 -j LOG --log-prefix "FOWARD: "


echo "Configuring iptables..."
#
# Default to drop packets
#iptables -P INPUT DROP
#iptables -P OUTPUT DROP
#iptables -P FORWARD DROP

#
# Allow all local loopback traffic
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

#
# Allow output on $WAN and $LAN if. Allow input on $LAN if.
iptables -A INPUT -i $LAN -j ACCEPT
iptables -A OUTPUT -o $WAN -j ACCEPT
iptables -A OUTPUT -o $LAN -j ACCEPT

iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

iptables -A FORWARD -o $LAN -m state --state ESTABLISHED,RELATED -j ACCEPT

iptables -A FORWARD -i $LAN -o $WAN -j ACCEPT
iptables -t nat -A POSTROUTING -o $WAN -j MASQUERADE

# Allow ICMP echo reply/echo request/destination unreachable/time exceeded
iptables -A INPUT -p icmp --icmp-type destination-unreachable -j ACCEPT
iptables -A INPUT -p icmp --icmp-type time-exceeded -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-reply -j ACCEPT

echo "done... Use ${LAN_IP} as default gateway on the client."
echo 
echo "    sudo route add default gw 10.0.8.50"
echo 
echo "...checking for active DHCP server on $LAN"
nmap --script broadcast-dhcp-discover -e $LAN 2> /dev/null
