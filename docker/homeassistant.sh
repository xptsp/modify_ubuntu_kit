#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs Home Assistant Supervisor."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installs Home Assistant Supervisor..."
#==============================================================================
wget https://raw.githubusercontent.com/home-assistant/supervised-installer/master/installer.sh -O /tmp/installer.sh
chmod +x /tmp/installer.sh
/tmp/installer.sh
rm /tmp/installer.sh
