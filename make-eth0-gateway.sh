#!/bin/bash

WAN="wlp2s0"
LAN="eth0"

LAN_IP=$1
if [[ "$LAN_IP" == "" ]]; then 
    LAN_IP="10.0.8.50"
    echo "*** Using default IP of $LAN_IP (pass $LAN IP with first parameter)"
fi

LAN_IP="$LAN_IP/24"


if [ "$(id -u)" != "0" ]; then 
    sudo $0 $@
    exit
fi


ifconfig $LAN up
ifconfig $LAN $LAN_IP

echo 1 > /proc/sys/net/ipv4/ip_forward
sysctl -w net.ipv4.ip_forward=1

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
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

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
