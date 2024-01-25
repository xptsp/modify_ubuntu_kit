#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs Ubuntu alternate repos on your computer."
	echo -e "${RED}NOTE:${NC} Not needed on Ubuntu 22.04!"
	echo ""
	exit 0
fi

#==============================================================================
# First: Decide what OS paths to use:
#==============================================================================
wget http://archive.ubuntu.com/ubuntu/pool/universe/g/gnome-browser-connector/chrome-gnome-shell_42.1-4_all.deb -O /tmp/chrome-gnome-shell_42.1-4_all.deb
wget http://archive.ubuntu.com/ubuntu/pool/universe/g/gnome-browser-connector/gnome-browser-connector_42.1-4_all.deb -O /tmp//gnome-browser-connector_42.1-4_all.deb
apt install /tmp/gnome-browser-connector_42.1-4_all.deb /tmp/chrome-gnome-shell_42.1-4_all.deb
