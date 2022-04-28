#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# If we are running Ubuntu 22.04 variants, we don't need this:
[[ "$(cat /etc/os-release | grep "VERSION=" | cut -d"\"" -f 2 | cut -d" " -f 1)" != "22.04" ]] && echo "NOTE: Not necessary for Ubuntu 22.04 variants!" && exit 1;

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs all other XFCE widgets on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing all other XFCE widgets..."
#==============================================================================
apt install -y xfce4-*plugin*
