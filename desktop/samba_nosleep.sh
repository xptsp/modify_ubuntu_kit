#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs and configures Samba on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Adding service to stop sleep while Samba is serving files:"
#==============================================================================
cp ${MUK_DIR}/files/samba_nosleep.service /etc/systemd/system/samba_nosleep.service
systemctl enable samba_nosleep
