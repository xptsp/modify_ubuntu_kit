#!/bin/bash
[[ -f /usr/local/finisher/settings.conf ]] && . /usr/local/finisher/settings.conf
MUK_DIR=${MUK_DIR:-"/opt/modify_ubuntu_kit"}
[[ ! -e ${MUK_DIR}/files/includes.sh ]] && (echo Missing includes file!  Aborting!; exit 1)
. ${MUK_DIR}/files/includes.sh

# No parameter specified?  Or maybe help requested?
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
	echo -e "${RED}Purpose:${NC} Installs ExFAT support on your computer."
	echo ""
	exit 0
fi

#==============================================================================
_title "Adding universe to apt repository..."
#==============================================================================
add-apt-repository -y universe && apt update

#==============================================================================
# If we are running Ubuntu 22.04 variants, we don't need this:
	#==============================================================================
if [[ "$(cat /etc/os-release | grep "VERSION=" | cut -d"\"" -f 2 | cut -d" " -f 1)" != "22.04" ]]; then
	_title "Installing ExFAT support on your computer"
	apt install -y exfat-fuse exfat-utils
fi
