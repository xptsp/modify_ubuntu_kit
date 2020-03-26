#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs a Split Tunnel VPN service on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Install required software for Split Tunnel VPN..."
#==============================================================================
apt install -y debconf-utils
echo "iptables-persistent iptables-persistent/autosave_v4 boolean false" | debconf-set-selections
echo "iptables-persistent iptables-persistent/autosave_v6 boolean false" | debconf-set-selections
apt install -y openvpn openvpn-systemd-resolved iptables-persistent p7zip-full curl

#==============================================================================
_title "Setting up VPN service and scripts..."
#==============================================================================
# First: Create our VPN service...
#==============================================================================
sed "s|%i|vpn|g" /lib/systemd/system/openvpn@.service > /etc/systemd/system/vpn.service
sed -i "s|/etc/openvpn/vpn|/etc/openvpn/vpn/vpn|g" /etc/systemd/system/vpn.service
sed -i "s|ExecStart=|ExecStartPre=/etc/openvpn/vpn/vpn_login.sh\nExecStart=|g" /etc/systemd/system/vpn.service

# Second: Link the scripts necessary in order to set up the service:
#==============================================================================
mkdir /etc/openvpn/vpn
for file in /opt/modify_ubuntu_kit/files/vpn_*.sh; do 
	ln -sf ${file} /etc/openvpn/vpn/$(basename ${file})
done
touch /etc/openvpn/vpn/vpn_creds
chmod 400 /etc/openvpn/vpn/vpn_creds
touch /etc/openvpn/vpn/vpn_last_update
chmod 400 /etc/openvpn/vpn/vpn_last_update

# Third: Configure to prevent DNS leaks:
#==============================================================================
sed -i "s|#     foreign_option_1='dhcp-option DNS 193.43.27.132'|foreign_option_3='dhcp-option DNS 1.1.1.1'|g" /etc/openvpn/update-resolv-conf
sed -i "s|#     foreign_option_2='dhcp-option DNS 193.43.27.133'|foreign_option_3='dhcp-option DNS 1.0.0.1'|g" /etc/openvpn/update-resolv-conf
sed -i "s|#     foreign_option_3='dhcp-option DOMAIN be.bnc.ch'|foreign_option_3='dhcp-option DNS 8.8.8.8'|g" /etc/openvpn/update-resolv-conf

# Fourth: Configure Split Tunnel VPN Routing
#==============================================================================
echo "200     htpc" >> /etc/iproute2/rt_tables

# Fifth: Change Reverse Path Filtering
#==============================================================================
cat << EOF > /etc/sysctl.d/9999-vpn.conf
net.ipv4.conf.all.rp_filter = 2
net.ipv4.conf.default.rp_filter = 2
net.ipv4.conf.enp0s3.rp_filter = 2
EOF

# Sixth: Establishing the default iptables rules...
#==============================================================================
iptables -F
iptables -A OUTPUT ! -o lo -m owner --uid-owner 9999 -j DROP
iptables-save > /etc/iptables/rules.v4

# Seventh: Call/Setup finisher task...
#==============================================================================
if ischroot; then
	systemctl disable vpn
	[[ -e /usr/local/finisher/tasks.d/30_vpn.sh ]] && rm /usr/local/finisher/tasks.d/30_vpn.sh
	ln -sf ${MUK_DIR}/files/tasks.d/30_vpn.sh /usr/local/finisher/tasks.d/30_vpn.sh
else
	/usr/local/finisher/tasks.d/30_vpn.sh
	systemctl enable vpn
	systemctl start vpn
fi
