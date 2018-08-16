#!/bin/bash

# check the dependencies 
if ! `hash udhcpd`; then
    echo "Install udhcpd first."
    exit 5
fi

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
    --unattended: Do not show DHCP server configuration screen

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

UNATTENDED=
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
        --unattended)       # Takes an option argument; ensure it has been specified.
            UNATTENDED="yes"
            shift
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

# Cleanup code 
finish() {
  echo
  echo_yellow "Stopping gateway..."
  iptables -P INPUT ACCEPT
  iptables -P FORWARD ACCEPT
  iptables -P OUTPUT ACCEPT
  iptables -F
  iptables -X
  iptables -t nat -F
  iptables -t nat -X
  iptables -t mangle -F
  iptables -t mangle -X
  iptables -t raw -F
  iptables -t raw -X
  echo_green "done..."
}
trap finish EXIT

LAN_IP="$LAN_IP"
NETMASK=24

echo_green "Using $WAN as WAN, $LAN as LAN and $LAN_IP/$NETMASK as IP of $LAN."

ifconfig $LAN up
ifconfig $LAN $LAN_IP/$NETMASK

echo 1 > /proc/sys/net/ipv4/ip_forward
sysctl -w net.ipv4.ip_forward=1 > /dev/null

# Clear iptables before configuring
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

echo_green "Starting the DHCP server on $LAN"
baseip=`echo $LAN_IP | cut -d"." -f1-3`
last_octet=${LAN_IP#$baseip.}
offset=0
[[ $last_octet -le 100 ]] && offset=100
start_ip="$baseip.$((offset + 5))"
end_ip="$baseip.$((offset + 10))"
#echo "DEBUG: baseip: $baseip, last octet: $last_octet, start: $start_ip, end: $end_ip"

# --------------------------------------------
TMP_CONFIG=$DIR/tmp_dhcp_config
cat << CONFIG > $TMP_CONFIG
# Sample minimal udhcpd configuration file 
#   (see https://udhcp.busybox.net/udhcpd.conf for full options)

# The start and end of the IP lease block
start       $start_ip
end         $end_ip 

# The interface that udhcpd will use
interface   $LAN

# Static leases map
#static_lease 00:60:08:11:CE:4E 192.168.0.54
#static_lease 00:60:08:11:CE:3E 192.168.0.44

# Other options
option dns 8.8.8.8
option subnet  255.255.255.0
option router  $LAN_IP

CONFIG

[[ "$UNATTENDED" == "yes" ]] || nano $TMP_CONFIG
touch /var/lib/misc/udhcpd.leases
udhcpd -f -I $LAN_IP $TMP_CONFIG
