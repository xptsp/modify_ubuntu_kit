#! /bin/bash
# Niftiest Software  www.niftiestsoftware.com
# Modified version by HTPC Guides  www.htpcguides.com

# The user that the VPN is restricted to:
export VPNUSER=htpc

# Get local ethernet name and IP address:
ETHERNET=$(lshw -c network -disable usb -short | grep -i "ethernet")
IFS=" " read -ra ETH_NAME <<< $ETHERNET
export NETIF=${ETH_NAME[1]}
[[ "$1" == "-v" ]] && echo "Ethernet Interface = $NETIF"
export LOCALIP=$(ip address show $NETIF | egrep -o '([0-9]{1,3}\.){3}[0-9]{1,3}' | egrep -v '255|(127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})' | tail -n1)/16
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

# allow incoming mapped port from allowed ports
if [[ ! -z "${PORTS[@]}" ]]; then
	for PORT in "${PORTS[@]}"; do
		iptables -A INPUT -i $INTERFACE -p tcp --dport $PORT -j ACCEPT
		iptables -A INPUT -i $INTERFACE -p udp --dport $PORT -j ACCEPT
	done
fi

# block everything incoming on $INTERFACE to prevent accidental exposing of ports
iptables -A INPUT -i $INTERFACE -j REJECT

# let $VPNUSER access lo and $INTERFACE, but no other interfaces:
iptables -A OUTPUT -o lo -m owner --uid-owner $VPNUSER -j ACCEPT
iptables -A OUTPUT -o $INTERFACE -m owner --uid-owner $VPNUSER -j ACCEPT
iptables -A OUTPUT -m owner --uid-owner $VPNUSER -j REJECT

# all packets on $INTERFACE needs to be masqueraded
iptables -t nat -A POSTROUTING -o $INTERFACE -j MASQUERADE

# setup each port in the "port_forward.list":
if [[ ! -z "${PORTS[@]}" ]]; then
	for PORT in "${PORTS[@]}"; do
		# forward mapped ports
		iptables -t nat -A PREROUTING -p tcp -i $INTERFACE --dport $PORT -j DNAT --to $LOCALIP
		iptables -t nat -A PREROUTING -p udp -i $INTERFACE --dport $PORT -j DNAT --to $LOCALIP
		iptables -A FORWARD -p tcp -i $INTERFACE -o $NETIF -d $LOCALIP --dport $PORT -j ACCEPT
		iptables -A FORWARD -p udp -i $INTERFACE -o $NETIF -d $LOCALIP --dport $PORT -j ACCEPT

		# allow output (to masqueraded address) from mapped port from port
		iptables -A OUTPUT -o $NETIF -p tcp --sport $PORT -j ACCEPT
		iptables -A OUTPUT -o $NETIF -p udp --sport $PORT -j ACCEPT
	done
fi

# reject connections from predator IP going over $NETIF
iptables -A OUTPUT ! --src $LOCALIP -o $NETIF -j REJECT

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
