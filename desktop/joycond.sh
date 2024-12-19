#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Compiles JoyCon daemon for your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing JoyCon daemon..."
#==============================================================================
apt install -y libevdev-dev build-essential cmake libevdev-dev git pkg-config libudev-dev joycond
