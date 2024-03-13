#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs all other XFCE widgets on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing all other XFCE widgets..."
#==============================================================================
[[ "$(apt list --installed xfce4 2> /dev/null | wc -l)" -eq 1 ]] && echo "XFCE4 not installed!  Aborting..." && exit 0
apt install -y xfce4-*plugin*
