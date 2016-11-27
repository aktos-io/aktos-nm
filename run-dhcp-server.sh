#!/bin/bash 

if [ "$(id -u)" != "0" ]; then 
        sudo $0 $@
        exit
fi

dnsmasq_conf="/etc/dnsmasq.conf"
echo "dnsmasq settings: "
cat $dnsmasq_conf | grep "^interface"
cat $dnsmasq_conf | grep "^dhcp-"

echo 
echo "restarting dnsmasq..."
/etc/init.d/dnsmasq restart

echo
echo "listing dhcp clients: "
cat /var/lib/misc/dnsmasq.leases

