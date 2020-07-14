#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Configures your system to autologin to the \"htpc\" user."
	echo ""
	exit 0
fi

#==============================================================================
_title "Setup the computer to always start Kodi on next login..."
#==============================================================================
[[ ! -d /usr/local/finisher/tasks.d ]] && mkdir -p /usr/local/finisher/tasks.d
ln -sf ${MUK_DIR}/files/tasks.d/51_x11docker.sh /usr/local/finisher/tasks.d/51_x11docker.sh
