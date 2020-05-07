#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs Remarkable on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing Remarkable for Linux..."
#==============================================================================
wget https://remarkableapp.github.io/files/remarkable_1.87_all.deb -O /tmp/remarkable_1.87_all.deb
apt install -y /tmp/remarkable_1.87_all.deb
rm /tmp/remarkable_1.87_all.deb
