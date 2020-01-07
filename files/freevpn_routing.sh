#! /bin/bash
# Niftiest Software  www.niftiestsoftware.com
# Modified version by HTPC Guides  www.htpcguides.com

# Are we root?  If not, get root access!
if [[ "$EUID" -ne 0 ]]; then
    $0
    exit
fi

[[ -z "$INTERFACE" ]] && INTERFACE=$(cat /etc/openvpn/freevpn/freevpn.conf | grep "dev " | cut -d" " -f 2)
[[ -z "$VPNUSER" ]] && VPNUSER="htpc"
GATEWAYIP=$(ip address show $INTERFACE | egrep -o '([0-9]{1,3}\.){3}[0-9]{1,3}' | egrep -v '255|(127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})' | tail -n1)
if [[ $(ip rule list | grep -c 0x1) == 0 ]]; then
    ip rule add from all fwmark 0x1 lookup $VPNUSER
fi
ip route replace default via $GATEWAYIP table $VPNUSER
ip route append default via 127.0.0.1 dev lo table $VPNUSER
ip route flush cache

# run update-systemd-resolved script to set VPN DNS
/etc/openvpn/update-systemd-resolved

exit 0
