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
apt install -y nautilus-admin nautilus-extension-brasero nautilus-filename-repairer nautilus-gtkhash nautilus-image-converter nautilus-hide nautilus-wipe folder-color  

# Install Nautilus Gnome Disks
#==============================================================================
DEST=/usr/share/nautilus-python/extensions/
DIR=/tmp/nautilus-gnome-disks
git clone https://github.com/thebitstick/nautilus-gnome-disks ${DIR}
install --mode=644 ${DIR}/nautilus-gnome-disks.py ${DEST}/
rm -rf ${DIR}
