#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs Atom Editor on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing Atom Editor for GitHub for Linux..."
#==============================================================================
wget https://github.com/atom/atom/releases/download/v1.60.0/atom-amd64.deb -O /tmp/atom.deb
apt install -y /tmp/atom.deb
rm /tmp/atom.deb
