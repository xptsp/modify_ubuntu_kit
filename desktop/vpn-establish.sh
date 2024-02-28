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
if [[ "$OS_VER" -lt 2204 ]]; then
	curl -s https://swupdate.openvpn.net/repos/repo-public.gpg | gpg --dearmor > /usr/share/keyrings/openvpn.gpg
	FILE=/etc/apt/sources.list.d/openvpn.list
	echo "deb [signed-by=/usr/share/keyrings/openvpn.gpg] http://build.openvpn.net/debian/openvpn/stable ${OS_NAME} main" > $FILE
	sed -i "s| impish | focal | g" $FILE
	apt update
fi
apt install -y debconf-utils
echo "iptables-persistent iptables-persistent/autosave_v4 boolean false" | debconf-set-selections
echo "iptables-persistent iptables-persistent/autosave_v6 boolean false" | debconf-set-selections
apt install -y openvpn openvpn-systemd-resolved iptables-persistent p7zip-full curl

#==============================================================================
_title "Setting up VPN service and scripts..."
#==============================================================================
# First: Create our VPN service...
#==============================================================================
[[ ! -d /lib/systemd/system/openvpn@freevpn.service.d ]] && mkdir /lib/systemd/system/openvpn@freevpn.service.d
cat << EOF > /lib/systemd/system/openvpn@freevpn.service.d/login.conf
[Service]
ExecStartPre=${MUK_DIR}/files/freevpn_login.sh
Restart=
Restart=always
EOF

# Second: Link the scripts necessary in order to set up the service:
#==============================================================================
touch /etc/openvpn/.vpn_creds
chmod 400 /etc/openvpn/.vpn_creds
touch /etc/openvpn/.vpn_last_update
chmod 400 /etc/openvpn/.vpn_last_update

# Third: Configure to prevent DNS leaks:
#==============================================================================
sed -i "s|#     foreign_option_1='dhcp-option DNS 193.43.27.132'|foreign_option_1='dhcp-option DNS 1.1.1.1'|g" /etc/openvpn/update-resolv-conf
sed -i "s|#     foreign_option_2='dhcp-option DNS 193.43.27.133'|foreign_option_2='dhcp-option DNS 1.0.0.1'|g" /etc/openvpn/update-resolv-conf
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

# Seventh: Add the "vpn" system user account:
#==============================================================================
useradd -M -r -d /home/vpn -s /usr/sbin/nologin vpn

# Seventh: Call/Setup finisher task...
#==============================================================================
add_taskd 30_vpn.sh
