#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs PCSX2 (Playstation 2 emulator) on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing PCSX2..."
#==============================================================================
add-apt-repository -y ppa:gregory-hainaut/pcsx2.official.ppa
apt-get install -y pcsx2
