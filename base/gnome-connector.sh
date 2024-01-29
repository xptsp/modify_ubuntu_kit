#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs Gnome browser connector."
	echo ""
	exit 0
fi

#==============================================================================
_title "Install Gnome browser connector..."
#==============================================================================
wget http://archive.ubuntu.com/ubuntu/pool/universe/g/gnome-browser-connector/gnome-browser-connector_42.1-4_all.deb -O /tmp//gnome-browser-connector_42.1-4_all.deb
apt install -y /tmp/gnome-browser-connector_42.1-4_all.deb
rm /tmp/gnome-browser-connector_42.1-4_all.deb
