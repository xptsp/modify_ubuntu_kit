#! /bin/bash
# Niftiest Software – www.niftiestsoftware.com
# Modified version by HTPC Guides – www.htpcguides.com

# The user that the VPN is restricted to:
export VPNUSER=vpn

# Get local ethernet name and IP address:
NETIF=($(lshw -c network -disable usb -short | grep -i "ethernet"))
export NETIF=${NETIF[1]}
[[ "$1" == "-v" ]] && echo "Ethernet Interface = $NETIF"
export LOCALIP=$(ip address show $NETIF | egrep -o '([0-9]{1,3}\.){3}[0-9]{1,3}' | egrep -v '255|(127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})' | tail -n1)
[[ "$1" == "-v" ]] && echo "Ethernet IP Address = $LOCALIP"

# Determine what the interface name is and IP address:
export INTERFACE=$(cat /etc/openvpn/vpn.conf | grep "dev " | cut -d" " -f 2)
[[ "$1" == "-v" ]] && echo "VPN Interface = $INTERFACE"
export GATEWAYIP=$(ip address show $INTERFACE | egrep -o '([0-9]{1,3}\.){3}[0-9]{1,3}' | egrep -v '255|(127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})' | tail -n1)
[[ "$1" == "-v" ]] && echo "VPN IP Address = $GATEWAYIP"

# flushes all the iptables rules, if you have other rules to use then add them into the script
iptables -F -t nat
iptables -F -t mangle
iptables -F -t filter

# mark packets from $VPNUSER
iptables -t mangle -A OUTPUT -j CONNMARK --restore-mark
iptables -t mangle -A OUTPUT ! --dest $LOCALIP -m owner --uid-owner $VPNUSER -j MARK --set-mark 0x1
iptables -t mangle -A OUTPUT --dest $LOCALIP -p udp --dport 53 -m owner --uid-owner $VPNUSER -j MARK --set-mark 0x1
iptables -t mangle -A OUTPUT --dest $LOCALIP -p tcp --dport 53 -m owner --uid-owner $VPNUSER -j MARK --set-mark 0x1
iptables -t mangle -A OUTPUT ! --src $LOCALIP -j MARK --set-mark 0x1
iptables -t mangle -A OUTPUT -j CONNMARK --save-mark

# allow responses
iptables -A INPUT -i $INTERFACE -m conntrack --ctstate ESTABLISHED -j ACCEPT

# block everything incoming on $INTERFACE to prevent accidental exposing of ports
iptables -A INPUT -i $INTERFACE -j REJECT

# let $VPNUSER access lo and $INTERFACE
iptables -A OUTPUT -o lo -m owner --uid-owner $VPNUSER -j ACCEPT
iptables -A OUTPUT -o $INTERFACE -m owner --uid-owner $VPNUSER -j ACCEPT

# all packets on $INTERFACE needs to be masqueraded
iptables -t nat -A POSTROUTING -o $INTERFACE -j MASQUERADE

# reject connections from predator IP going over $NETIF
iptables -A OUTPUT ! --src $LOCALIP -o $NETIF -j REJECT

#ADD YOUR RULES HERE

# configure routes for the packets we just marked:
if [[ `ip rule list | grep -c 0x1` == 0 ]]; then
 	ip rule add from all fwmark 0x1 lookup $VPNUSER
fi
ip route replace default via $GATEWAYIP table $VPNUSER
ip route append default via 127.0.0.1 dev lo table $VPNUSER
ip route flush cache

# run update-systemd-resolved script to set VPN DNS
/etc/openvpn/update-systemd-resolved

exit 0
