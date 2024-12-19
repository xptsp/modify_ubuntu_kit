#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs Transmission and Transmission Remote GTK on your computer."
	echo ""
	exit 0
fi

# Seventh: Make sure our VPN is created on the system:
#==============================================================================
[[ ! -e /etc/openvpn ]] && ${MUK_DIR}/desktop/vpn_establish.sh

#==============================================================================
_title "Installing Transmission Remote GTK..."
#==============================================================================
wget http://ftp.de.debian.org/debian/pool/main/t/transmission-remote-gtk/transmission-remote-gtk_1.5.1-1_amd64.deb -O /tmp/transmission-remote-gtk_1.5.1-1_amd64.deb
apt purge -y --autoremove transmission*
apt install -y /tmp/transmission-remote-gtk_1.5.1-1_amd64.deb
