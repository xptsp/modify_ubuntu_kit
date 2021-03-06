#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs ethernet suspend/hibernate fix on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Adding script to deal with no ethernet connection after suspend/hibernate..."
#==============================================================================
ln -sf ${MUK_DIR}/files/restart_network.sh /etc/pm/sleep.d/99-network.sh
