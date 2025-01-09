#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs dnsmasq onto your machine."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing DNSMasq..."
#==============================================================================
# Disable and stop systemd-resolved.  We don't want this service restarted after installation!
$(whereis systemctl | awk '{print $2}') disable --now systemd-resolved

# Remove symlinked "/etc/resolv.conf" and recreate it to local DNS server, then Cloudflare: 
unlink /etc/resolv.conf
cat << EOF > /etc/resolv.conf
nameserver 127.0.0.1
nameserver 1.1.1.1
nameserver 1.0.0.1
EOF

# Actually install the dnsmasq service:
apt update
apt install dnsmasq -y

# Configure and restart dnsmasq:
FILE=/etc/dnsmasq.conf
mv ${FILE} ${FILE}.bak
cat << EOF > ${FILE}
bind-interfaces

# Listen on this specific port instead of the standard DNS port
# (53). Setting this to zero completely disables DNS function,
# leaving only DHCP and/or TFTP.
port=53

# Never forward plain names (without a dot or domain part)
domain-needed

# Never forward addresses in the non-routed address spaces.
bogus-priv

# By  default,  dnsmasq  will  send queries to any of the upstream
# servers it knows about and tries to favour servers to are  known
# to  be  up.  Uncommenting this forces dnsmasq to try each query
# with  each  server  strictly  in  the  order  they   appear   in
# /etc/resolv.conf
strict-order

# Set this (and domain: see below) if you want to have a domain
# automatically added to simple names in a hosts-file.
expand-hosts

# Set the domain for dnsmasq. this is optional, but if it is set, it
# does the following things.
# 1) Allows DHCP hosts to have fully qualified domain names, as long
#     as the domain part matches this setting.
# 2) Sets the "domain" DHCP option thereby potentially setting the
#    domain of all systems configured by DHCP
# 3) Provides the domain part for "expand-hosts"
#domain=thekelleys.org.uk
domain=example.com

# Set Listen address
listen-address=127.0.0.1  # Set to Server IP for network responses
EOF
systemctl restart dnsmasq
