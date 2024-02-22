#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs Google Chrome on your computer."
	echo ""
	exit 0
fi

#==============================================================================
# Make sure gnome-browser-connector is installed!
#==============================================================================
apt list --installed gnome-browser-connector 2>&1 | grep -q gnome-browser-connector || ../base/gnome-connector.sh

#==============================================================================
_title "Installing Google Chrome..."
#==============================================================================
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O /tmp/google-chrome-stable_current_amd64.deb
wget http://archive.ubuntu.com/ubuntu/pool/universe/g/gnome-browser-connector/chrome-gnome-shell_42.1-4_all.deb -O /tmp/chrome-gnome-shell_42.1-4_all.deb
apt install -y /tmp/google-chrome-stable_current_amd64.deb /tmp/chrome-gnome-shell_42.1-4_all.deb
rm /tmp/google-chrome-stable_current_amd64.deb /tmp/chrome-gnome-shell_42.1-4_all.deb
