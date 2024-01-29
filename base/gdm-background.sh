#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Downloads GDM change background script."
	echo ""
	exit 0
fi

#==============================================================================
_title "Downloading GDM change background script..."
#==============================================================================
apt install -y wget libglib2.0-dev-bin
wget github.com/thiggy01/change-gdm-background/raw/master/change-gdm-background -O /usr/local/bin/change-gdm-background
chmod +x /usr/local/bin/change-gdm-background
