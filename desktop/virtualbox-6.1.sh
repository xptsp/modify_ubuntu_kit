#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs VirtualBox 6.1 and extension pack on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Install VirtualBox and VirtualBox Extension Pack..."
#==============================================================================
# First: Install the software :p
#==============================================================================
wget https://download.virtualbox.org/virtualbox/6.1.2/virtualbox-6.1_6.1.2-135662~Ubuntu~bionic_amd64.deb -O /tmp/virtualbox-6.1_6.1.2-135662~Ubuntu~bionic_amd64.deb
apt install -y /tmp/virtualbox-6.1_6.1.2-135662~Ubuntu~bionic_amd64.deb
rm /tmp/virtualbox-6.1_6.1.2-135662~Ubuntu~bionic_amd64.deb
