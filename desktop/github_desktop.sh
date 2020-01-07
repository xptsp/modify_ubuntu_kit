#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs GitHub Desktop for Linux on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Installing GitHub Desktop for Linux..."
#==============================================================================
wget https://github.com/shiftkey/desktop/releases/download/release-2.1.0-linux1/GitHubDesktop-linux-2.1.0-linux1.deb -O /tmp/GitHubDesktop-linux-2.1.0-linux1.deb
apt install -y /tmp/GitHubDesktop-linux-2.1.0-linux1.deb
rm /tmp/GitHubDesktop-linux-2.1.0-linux1.deb
