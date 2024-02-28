#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs ClamAV on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing ClamAV on your computer..."
#==============================================================================
apt install -y clamav clamtk clamav-daemon

#==============================================================================
_title "Updating ClamAV virus definitions..."
#==============================================================================
systemctl stop clamav-freshclam
freshclam
systemctl start clamav-freshclam
