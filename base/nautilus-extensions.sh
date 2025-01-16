#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs Nautilus extensions and tweaks."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installs Nautilus options..."
#==============================================================================
# First: Set standard size instead of small icon size  
dbus-launch --exit-with-session gsettings set org.gnome.nautilus.icon-view default-zoom-level 'standard'

#==============================================================================
_title "Installs Nautilus extensions available in Ubuntu repo..."
#==============================================================================
test -f /etc/apt/sources.list.d/xptsp_ppa.list || ${MUK_DIR}/base/custom-xptsp.sh
apt install -y nautilus-admin nautilus-extension-brasero nautilus-filename-repairer nautilus-gtkhash nautilus-image-converter nautilus-hide nautilus-wipe folder-color nautilus-gnome-disks  
