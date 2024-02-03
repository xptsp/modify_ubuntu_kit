#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs VLC, replacing Gnome Totem (if installed)."
	echo ""
	exit 0
fi

#==============================================================================
_title "Removing Gnome Terminal..."
#==============================================================================
apt purge -y --autoremove totem totem-plugins

#==============================================================================
_title "Installing XFCE4 Terminal..."
#==============================================================================
apt install -y vlc
